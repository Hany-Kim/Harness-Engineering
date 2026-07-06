package com.example.app.arch;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.fields;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.methods;

import com.tngtech.archunit.core.domain.JavaClass;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;
import com.tngtech.archunit.library.Architectures;
import java.util.Collection;
import java.util.Map;
import java.util.Optional;

// 컨벤션 사다리 1층: 계층·반환·주입 규칙을 산문이 아니라 테스트로 강제한다.
// 이 테스트가 실패하면 커밋 게이트(./gradlew test)가 커밋을 차단한다.
// 프로젝트에 이식할 때 packages 상수만 실제 패키지로 바꾼다.
@AnalyzeClasses(packages = "com.example.app")
class LayeringArchTest {

    // 1) 레이어드 아키텍처: 의존성은 한 방향 — controller → service → repository.
    @ArchTest
    static final ArchRule 레이어_의존성은_한_방향이다 = Architectures.layeredArchitecture()
            .consideringOnlyDependenciesInLayers()
            .layer("Controller").definedBy("..controller..")
            .layer("Service").definedBy("..service..", "..note..") // 도메인 패키지에 서비스가 있으면 포함
            .layer("Repository").definedBy("..repository..")
            .whereLayer("Controller").mayNotBeAccessedByAnyLayer()
            .whereLayer("Service").mayOnlyBeAccessedByLayers("Controller")
            .whereLayer("Repository").mayOnlyBeAccessedByLayers("Service");

    // 2) Repository 단건 조회는 Optional<T> 반환 — null 반환 관례를 타입으로 봉쇄.
    //    컬렉션/Map/Stream 반환(다건 조회)은 규칙 대상에서 제외한다(빈 컬렉션 반환).
    @ArchTest
    static final ArchRule 리포지토리_단건_조회는_Optional을_반환한다 = methods()
            .that().areDeclaredInClassesThat().haveSimpleNameEndingWith("Repository")
            .and().haveNameMatching("(find|get)By.*")
            .and().haveRawReturnType(단건_반환_타입())
            .should().haveRawReturnType(Optional.class)
            .because("단건 조회의 null 반환은 호출부 NPE로 이어진다 — Optional로 강제 "
                    + "(docs/conventions/new-api-endpoint.md)");

    private static com.tngtech.archunit.base.DescribedPredicate<JavaClass> 단건_반환_타입() {
        return new com.tngtech.archunit.base.DescribedPredicate<>("단건 반환 타입(컬렉션/Optional 제외)") {
            @Override
            public boolean test(JavaClass returnType) {
                return !returnType.isAssignableTo(Collection.class)
                        && !returnType.isAssignableTo(Map.class)
                        && !returnType.isAssignableTo(java.util.stream.Stream.class)
                        && !returnType.isEquivalentTo(Optional.class)
                        && !returnType.isEquivalentTo(void.class);
            }
        };
    }

    // 3) 필드 주입 금지 — 생성자 주입만 (@RequiredArgsConstructor + private final).
    @ArchTest
    static final ArchRule 필드_Autowired_금지 = fields()
            .should().notBeAnnotatedWith("org.springframework.beans.factory.annotation.Autowired")
            .because("생성자 주입만 허용 — 테스트 가능성과 불변성을 위해");
}
