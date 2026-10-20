# 군부대 맵 저장본

2026-10-20 작업 결과입니다. `MilitaryRP.rbxlx`를 Studio에서 열면 현재 맵과 게임 소스가 함께 로드됩니다.

- `Workspace/MilitaryBaseMap`: 실제 배치와 위치를 보존한 완성 맵
- 건물 18동: 본부 3층, 나머지 17동 2층
- 붉은 벽돌 외벽, 창틀과 돌 장식, 경사지붕, 빗물받이, 현관 조명
- 내부 계단, 층별 바닥·난간, 생활관 침상과 가구
- 연병장, 사격장, KCTC 훈련구역, 도로·주차장·외곽 시설
- 이전 건물: `ServerStorage/MilitaryBuildings_Backup_20261020_184201`

## 검증

Studio에서 18동의 각 위층까지 총 19개 이동 경로 검사가 성공했습니다. 건물 파트 12,848개 모두 고정되어 있습니다. 저장한 XML에서 맵 파트 13,830개와 전체 계층을 확인했습니다. 원격 main에 있던 최신 HQ 배지 소스도 저장 파일에 동기화했습니다.

## 다시 만들기

`tools/map/BuildMilitaryBase.luau`와 `tools/map/UpgradeBrickBuildings.luau`는 Studio 편집 모드 명령줄에서 실행하는 제작 도구입니다. 서버 스크립트로 넣지 마세요. 새 빈 장소에서는 Build → Upgrade 순서로 실행합니다. Build는 기존 MilitaryBaseMap이 있으면 중단합니다. Upgrade는 현재 건물 위치를 유지하며 이전 건물을 ServerStorage에 백업합니다.

제작 도구의 초기 좌표와 현재 Studio에서 이동한 맵 좌표는 다릅니다. **현재 배치를 그대로 복원하려면 MilitaryRP.rbxlx를 사용하세요.**

`tools/build_place.py`와 현재 Rojo 기본 프로젝트는 기본 테스트 맵을 생성하므로 완성 맵 파일을 덮어쓰는 용도로 사용하지 마세요. 소스만 갱신하려면 기존 맵을 보존하는 `tools/sync_place.py`를 사용하세요.

Git 업로드는 Roblox 게시와 별개입니다.
