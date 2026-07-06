package com.example.app.note;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;

import com.example.app.dto.NoteResponse;
import java.util.Optional;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

// 테스트 표본: given/when/then + happy path + 실패 경로 (testing-conventions 참조).
// WHY: 서비스 "단위" 테스트라 Repository를 목킹한다. 통합 테스트는 Testcontainers로.
@ExtendWith(MockitoExtension.class)
class NoteServiceTest {

    @Mock
    private NoteRepository noteRepository;

    @InjectMocks
    private NoteService noteService;

    @Test
    @DisplayName("제목으로 노트를 찾으면 DTO로 변환해 반환한다")
    void 제목으로_노트를_찾으면_DTO로_변환해_반환한다() {
        // given
        given(noteRepository.findByTitle("hello"))
                .willReturn(Optional.of(new Note("hello", "world")));

        // when
        NoteResponse response = noteService.getByTitle("hello");

        // then
        assertThat(response.title()).isEqualTo("hello");
        assertThat(response.body()).isEqualTo("world");
    }

    @Test
    @DisplayName("노트가 없으면 도메인 예외를 던진다")
    void 노트가_없으면_도메인_예외를_던진다() {
        // given
        given(noteRepository.findByTitle("missing")).willReturn(Optional.empty());

        // when / then
        assertThatThrownBy(() -> noteService.getByTitle("missing"))
                .isInstanceOf(NoteNotFoundException.class);
    }
}
