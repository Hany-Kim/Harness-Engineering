package com.example.app.controller;

import com.example.app.dto.NoteResponse;
import com.example.app.note.NoteService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

// Runtime/API 계층: 요청/응답 매핑만. 비즈니스 판단·리포지토리 접근 금지(ArchUnit).
@RestController
@RequestMapping("/api/notes")
@RequiredArgsConstructor
public class NoteController {

    private final NoteService noteService;

    @GetMapping("/{title}")
    public NoteResponse getNote(@PathVariable String title) {
        return noteService.getByTitle(title);
    }
}
