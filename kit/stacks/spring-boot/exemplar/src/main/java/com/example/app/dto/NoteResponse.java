package com.example.app.dto;

import com.example.app.note.Note;

// Types 계층(dto): 컨트롤러 경계를 넘는 것은 항상 DTO — 엔티티 노출 금지.
public record NoteResponse(Long id, String title, String body) {

    public static NoteResponse from(Note note) {
        return new NoteResponse(note.getId(), note.getTitle(), note.getBody());
    }
}
