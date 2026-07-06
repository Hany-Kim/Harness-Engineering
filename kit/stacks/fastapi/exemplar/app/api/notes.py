# Runtime/API 계층: 매핑만. 서비스에 Depends로 의존하고 리포지토리는 모른다.
from fastapi import APIRouter, Depends, HTTPException

from app.repositories.note_repository import NoteRepository
from app.schemas.note import NoteCreateRequest, NoteResponse
from app.services.note_service import NoteNotFoundError, NoteService

router = APIRouter(prefix="/api/notes", tags=["notes"])

# WHY: 요청 스코프 DI의 표본 — 실제 프로젝트에서는 세션/설정을 주입하는 공용
# provider(app/core/)로 대체한다. 모듈 전역에서 client를 직접 만들지 않는다.
_repository = NoteRepository()


def get_note_service() -> NoteService:
    return NoteService(_repository)


@router.post("", response_model=NoteResponse, status_code=201)
def create_note(
    request: NoteCreateRequest,
    service: NoteService = Depends(get_note_service),
) -> NoteResponse:
    return service.create(request)


@router.get("/{note_id}", response_model=NoteResponse)
def get_note(
    note_id: int,
    service: NoteService = Depends(get_note_service),
) -> NoteResponse:
    try:
        return service.get(note_id)
    except NoteNotFoundError as error:
        # 도메인 예외 → HTTP 매핑은 여기(api 계층)서만 일어난다.
        raise HTTPException(status_code=404, detail=str(error)) from error
