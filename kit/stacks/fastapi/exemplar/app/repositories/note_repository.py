# Repository 계층: 저장소 접근만. 비즈니스 판단 금지.
# 규칙: 단건 조회는 `T | None` 반환 — None 처리는 호출부(서비스)의 책임.
# WHY: 인메모리 구현은 표본 단순화다. 실제 구현은 AsyncSession을 주입받되
# 시그니처와 계층 위치는 그대로 유지한다.
from app.schemas.note import NoteResponse


class NoteRepository:
    def __init__(self) -> None:
        self._notes: dict[int, NoteResponse] = {}
        self._next_id = 1

    def save(self, title: str, body: str) -> NoteResponse:
        note = NoteResponse(id=self._next_id, title=title, body=body)
        self._notes[note.id] = note
        self._next_id += 1
        return note

    def find_by_id(self, note_id: int) -> NoteResponse | None:
        return self._notes.get(note_id)

    def find_all(self) -> list[NoteResponse]:
        # 다건 조회는 빈 리스트 반환 — None을 반환하지 않는다.
        return list(self._notes.values())
