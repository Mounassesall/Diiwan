import json
import logging
import os
from concurrent.futures import ThreadPoolExecutor, TimeoutError as FuturesTimeoutError
from typing import Optional

from django.conf import settings

from .analyseur import QueryIntent, analyser_question
from .validateur import FIELDS_WHITELIST, OPERATIONS_WHITELIST, REGIONS_WHITELIST, valider_intention

logger = logging.getLogger(__name__)

MAX_QUESTION_LENGTH = 500
GEMINI_TIMEOUT_SECONDS = 5


def _intent_from_payload(payload: dict) -> QueryIntent:
    regions = payload.get("regions") or []
    if isinstance(regions, str):
        regions = [regions]

    return QueryIntent(
        indicator=payload.get("indicator"),
        regions=regions,
        start_year=payload.get("start_year"),
        end_year=payload.get("end_year"),
        operation=payload.get("operation") or "value",
        limit=payload.get("limit"),
        chart_type=payload.get("chart_type"),
        needs_clarification=bool(payload.get("needs_clarification")),
        clarification_message=payload.get("clarification_message"),
        is_out_of_scope=bool(payload.get("is_out_of_scope")),
    )


def extraire_intention_gemini(question: str) -> Optional[QueryIntent]:
    if not getattr(settings, "USE_GENERATIVE_AI", False):
        return None

    if not question or len(question) > MAX_QUESTION_LENGTH:
        return None

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or api_key == "ta_vraie_cle_api_ici":
        return None

    prompt = (
        "Extrais l'intention statistique depuis la question utilisateur.\n"
        f"Indicateurs valides : {', '.join(FIELDS_WHITELIST)}\n"
        f"Régions valides : {', '.join(REGIONS_WHITELIST)}\n"
        f"Opérations valides : {', '.join(OPERATIONS_WHITELIST)}\n"
        "Réponds uniquement en JSON avec les clés : "
        "indicator, regions, start_year, end_year, operation, limit, chart_type, "
        "needs_clarification, clarification_message, is_out_of_scope.\n"
        f"Question : {question[:MAX_QUESTION_LENGTH]}"
    )

    try:
        import google.generativeai as genai

        genai.configure(api_key=api_key)
        model = genai.GenerativeModel(
            "gemini-2.0-flash",
            generation_config={
                "temperature": 0.1,
                "response_mime_type": "application/json",
            },
        )

        with ThreadPoolExecutor(max_workers=1) as executor:
            future = executor.submit(model.generate_content, prompt)
            response = future.result(timeout=GEMINI_TIMEOUT_SECONDS)

        payload = json.loads(response.text)
        return _intent_from_payload(payload)
    except (FuturesTimeoutError, json.JSONDecodeError, ValueError, AttributeError, ImportError):
        return None
    except Exception:
        return None


def resoudre_intention(question: str) -> QueryIntent:
    intent_gemini = extraire_intention_gemini(question)
    if intent_gemini is not None:
        erreurs = valider_intention(intent_gemini)
        if not erreurs:
            logger.info(
                "Intention validée via IA : indicator=%s operation=%s regions=%s start=%s end=%s",
                intent_gemini.indicator,
                intent_gemini.operation,
                intent_gemini.regions,
                intent_gemini.start_year,
                intent_gemini.end_year,
            )
            return intent_gemini

    return analyser_question(question)
