# Service 계층: 비즈니스 흐름. 리포지토리의 None을 도메인 예외로 변환한다.
# WHY: HTTP 상태코드 매핑은 api 계층 책임 — 서비스는 웹을 모른다.
from app.repositories.note_repository import NoteRepository
from app.schemas.note import NoteCreateRequest, NoteResponse


class NoteNotFoundError(Exception):
    def __init__(self, note_id: int) -> None:
        super().__init__(f"note not found: {note_id}")
        self.note_id = note_id


class NoteService:
    def __init__(self, repository: NoteRepository) -> None:
        self._repository = repository

    def create(self, request: NoteCreateRequest) -> NoteResponse:
        return self._repository.save(request.title, request.body)

    def get(self, note_id: int) -> NoteResponse:
        note = self._repository.find_by_id(note_id)
        if note is None:
            raise NoteNotFoundError(note_id)
        return note
