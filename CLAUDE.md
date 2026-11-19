# 프라이빗 메모 — 작업 규칙

- 기능 기준 문서는 `docs/PRD.md`다. 동작 규칙이 바뀌면 코드와 함께 PRD도 고친다.
- `docs/PRD.md`를 고쳐 커밋했으면, Claude 웹 페이지(Artifact)도 같은 URL로 다시 올린다.
  1. `python3 tools/prd_page/build.py . <출력경로>/private-memo-prd.html`
  2. 생성한 HTML을 Artifact `https://claude.ai/artifact/C2oPB4FkgeGTanMqGXt38J` 에 publish (url 지정, 새 링크 만들지 않기)
- 테스트: `flutter analyze`, `flutter test` 모두 통과한 뒤 커밋한다.
- DB 스키마(`lib/data/database.dart`)를 바꾸면 `dart run build_runner build`로 생성 코드를 다시 만든다.
- 커밋을 푸시할 때마다 `main`으로 가는 PR을 만든다(이미 열린 PR이 있으면 그 PR에 커밋이 쌓이므로 새로 만들지 않는다). 머지는 사용자가 직접 한다.
