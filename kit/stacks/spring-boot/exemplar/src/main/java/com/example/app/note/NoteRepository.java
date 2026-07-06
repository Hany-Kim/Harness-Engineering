package com.example.app.note;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

// Repository 계층: 쿼리만. 비즈니스 판단 금지.
// 규칙(ArchUnit이 강제): 단건 조회는 Optional<T> — null 반환 관례를 타입으로 봉쇄한다.
// 컬렉션 조회는 빈 컬렉션을 반환하며 Optional로 감싸지 않는다.
public interface NoteRepository extends JpaRepository<Note, Long> {

    Optional<Note> findByTitle(String title);

    List<Note> findByTitleContaining(String keyword);
}
