# 테스트 표본: happy path + 404/422 실패 경로 (testing-conventions 참조).
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.api.notes import router


def build_client() -> TestClient:
    app = FastAPI()
    app.include_router(router)
    return TestClient(app)


def test_노트를_생성하고_조회한다() -> None:
    # given
    client = build_client()
    # when
    created = client.post("/api/notes", json={"title": "hello", "body": "world"})
    fetched = client.get(f"/api/notes/{created.json()['id']}")
    # then
    assert created.status_code == 201
    assert fetched.status_code == 200
    assert fetched.json()["title"] == "hello"


def test_없는_노트를_조회하면_404를_반환한다() -> None:
    client = build_client()
    response = client.get("/api/notes/99999")
    assert response.status_code == 404


def test_제목이_비면_422를_반환한다() -> None:
    # then — 경계(Pydantic) 검증이 서비스까지 가기 전에 막는다
    client = build_client()
    response = client.post("/api/notes", json={"title": "", "body": ""})
    assert response.status_code == 422
