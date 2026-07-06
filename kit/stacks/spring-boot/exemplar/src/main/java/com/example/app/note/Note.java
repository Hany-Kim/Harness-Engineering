package com.example.app.note;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

// Types 계층(domain): 엔티티는 서비스 밖으로 내보내지 않는다 — 컨트롤러는 DTO만 본다.
@Entity
public class Note {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

    private String body;

    protected Note() {
        // WHY: JPA 스펙이 요구하는 기본 생성자 — 외부 생성은 아래 생성자만 사용.
    }

    public Note(String title, String body) {
        this.title = title;
        this.body = body;
    }

    public Long getId() {
        return id;
    }

    public String getTitle() {
        return title;
    }

    public String getBody() {
        return body;
    }
}
