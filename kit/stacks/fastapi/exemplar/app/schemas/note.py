# Types 계층(schemas): 경계에서 검증하고, 이후 코드는 타입을 신뢰한다.
from pydantic import BaseModel, Field


class NoteCreateRequest(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    body: str = ""


class NoteResponse(BaseModel):
    id: int
    title: str
    body: str
