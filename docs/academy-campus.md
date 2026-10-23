# 육사 지도 참고 캠퍼스 (2026-10-22)

첨부한 공개 안내도의 구역 관계를 참고한 RP용 재구성이다. 실측 복제나 실제 내부 도면이 아니다. 내부는 창작했다.

- 부지 1700 × 1500 studs, 건물 18동, 지상 1–4층.
- 서쪽 생활관 A/B 각 4층, 북쪽 본부 3층과 강당 2층, 동쪽 교육관·도서관 2–3층.
- 병원, 식당, 박물관, 군수지원단, 군악대, 체육관, 장교회관, 안내소, 위병소.
- 중앙 기존 ExamDrillGround 보존, 연못·다리·기념광장, 남쪽 육상/축구/농구 시설, 정문·주차장.
- 창문 개구부와 유리, 층간 띠, 창턱, 처마, 배수관, 옥상 공조기, 내부 복도·방 구획·계단·용도별 가구.
- 순수 정적 geometry 19,619 parts + 투명 Origin 1개. 런타임 생성 스크립트 없음.

## 결과

`MilitaryRP.rbxlx`: 기존 완성 맵을 수정한 파일. 기존 소스 전체 해시가 건축 전후 동일함을 검사했다.
`assets/academy/AcademyCampus.rbxmx`: 새 캠퍼스만 별도 모델. 기존 시험 연병장은 포함하지 않는다.
`assets/academy/manifest.json`: 재현 가능한 geometry 데이터.
`tools/map/build_academy.py`: manifest 생성.
`tools/map/save_academy.py`: 최초 merge용, 이미 설치된 파일에는 재실행 거부.

## 검증

- Studio Edit: 18개 층수 범위, 19,620개 파트 Anchored, 계단 528개 지지면 검사 통과.
- 상층 계단 연결문 22곳 확보, 계단을 얇은 디딤판으로 수정해 층간 머리 공간 확보.
- Studio Play: 실제 캐릭터로 생활관 A 1층 → 2층 계단 → 2층 복도 → 4층 복도 이동 성공. 마지막 캐릭터 위치 약 (-580.62, 51.74, -279.94).
- XML 재파싱 통과. 원래 게임 소스 변경 없음.
- `python3 tools/test.py`: 공식 Luau CLI/컴파일러 미설치로 실행 불가.
- 기존 자산 203785492의 타입 불일치 경고가 Play 출력에 있음. 새 캠퍼스는 외부 asset ID를 사용하지 않음.
- 다중 사용자, DataStore 통합, 모바일 성능 테스트는 미실시. 온라인 배포하지 않음.

## 복원

전체 파일 백업: `backups/MilitaryRP.before-academy-20261022.rbxlx`.
Studio 기존 geometry: `ServerStorage.BeforeAcademy_20261022` (원본 인스턴스 그대로 보관).
새 geometry는 `Workspace.AcademyCampus`.
연병장에 적용한 평행이동은 (-324.644165, 0, 10.0011). 복원 시 역이동한다.
RankSpawn의 원래 위치는 (0, 0.5, 0), 새 위치는 (620, 1, 575).
Studio에만 있던 임시 Scene/Part도 Studio 복원 폴더에 보관했다. 기존 디스크 파일에 없던 이 임시 geometry는 디스크 백업에는 없다.
