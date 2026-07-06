package com.example.app.note;

import com.example.app.dto.NoteResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Service 계층: 비즈니스 흐름 + 트랜잭션. 생성자 주입만(필드 @Autowired 금지 — ArchUnit).
@Service
@RequiredArgsConstructor
public class NoteService {

    private final NoteRepository noteRepository;

    // WHY: Repository의 Optional은 서비스에서 해소한다 — 컨트롤러에 Optional을
    // 넘기면 404 변환 책임이 UI 경계로 새어 나간다.
    @Transactional(readOnly = true)
    public NoteResponse getByTitle(String title) {
        Note note = noteRepository
                .findByTitle(title)
                .orElseThrow(() -> new NoteNotFoundException(title));
        return NoteResponse.from(note);
    }
}
