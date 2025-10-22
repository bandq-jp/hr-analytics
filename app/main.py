from __future__ import annotations

import logging
from pathlib import Path
from typing import Dict, List

from fastapi import FastAPI, HTTPException
from fastapi.concurrency import run_in_threadpool

from services.pipeline import PipelineService, build_pipeline_service

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

app = FastAPI(
    title="Hiring Analytics Pipeline",
    version="0.1.0",
)

PROJECT_ROOT = Path(__file__).resolve().parent.parent
TRANSFORM_SQL_DIR = PROJECT_ROOT / "db" / "sql" / "transform"


def get_pipeline() -> PipelineService:
    pipeline: PipelineService = getattr(app.state, "pipeline", None)
    if pipeline is None:
        raise HTTPException(status_code=503, detail="Pipeline is not ready")
    return pipeline


@app.on_event("startup")
def startup_event() -> None:
    try:
        logger.info("Initialising pipeline service")
        app.state.pipeline = build_pipeline_service()
        logger.info("Pipeline service initialised successfully")
    except Exception as e:
        logger.error(f"Failed to initialise pipeline service: {e}")
        # Don't raise the exception to allow the app to start
        # The pipeline will be None and endpoints will return 503


@app.on_event("shutdown")
def shutdown_event() -> None:
    pipeline: PipelineService | None = getattr(app.state, "pipeline", None)
    if pipeline:
        pipeline.close()
        logger.info("Pipeline service shutdown complete")


@app.get("/healthz")
async def healthcheck() -> Dict[str, str]:
    pipeline: PipelineService | None = getattr(app.state, "pipeline", None)
    if pipeline is None:
        return {"status": "starting", "pipeline": "not_ready"}
    return {"status": "ok", "pipeline": "ready"}


@app.post("/ingest/run")
async def ingest() -> Dict[str, Dict[str, int]]:
    pipeline = get_pipeline()
    result = await run_in_threadpool(pipeline.run_ingest)
    return {"status": "ok", "rows_synced": result}


@app.post("/transform/run")
async def transform() -> Dict[str, Dict[str, str]]:
    pipeline = get_pipeline()
    if not TRANSFORM_SQL_DIR.exists():
        logger.warning("Transformation SQL directory missing: %s", TRANSFORM_SQL_DIR)
        raise HTTPException(status_code=500, detail="Transformation SQL not found")

    sql_files: List[Path] = sorted(TRANSFORM_SQL_DIR.glob("*.sql"))
    if not sql_files:
        raise HTTPException(status_code=500, detail="No transformation SQL files found")

    result = await run_in_threadpool(pipeline.run_transform, sql_files)
    return {"status": "ok", "executed": result}
