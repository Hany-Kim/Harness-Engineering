package com.example.app.note;

// WHY: 공용 예외 계층 표본 — 도메인 예외를 던지고 HTTP 매핑은 전역 핸들러가 담당한다.
// 서비스가 ResponseStatusException 같은 웹 계층 타입을 알면 계층이 역류한다.
public class NoteNotFoundException extends RuntimeException {

    public NoteNotFoundException(String title) {
        super("note not found: " + title);
    }
}
