# 🌿 Plantario - Team Zero | KHUTHON 2025

![banner](https://img.shields.io/badge/Team-Zero-brightgreen) ![event](https://img.shields.io/badge/Event-KHUTHON2025-blue)

> KHUTHON 2025 참가작  
> Flutter 기반 BLE(저전력 블루투스) 스마트 식물 관리 시스템

---

**Plantario**는 사용자의 식물을 IoT 기반으로 스마트하게 관리할 수 있는 Flutter 앱입니다.  
Arduino 센서 모듈을 통해 수집된 데이터를 실시간으로 시각화하고,  
식물 정보 등록, 커뮤니티 게시판, 사용자 프로필 등 다양한 기능을 제공합니다.

---

## 🌱 주요 기능

- **실시간 센서 데이터 확인**
  - 조도, 수분, 온도, 습도 데이터 표시
  - BLE 디바이스 자동 연결 (즐겨찾기 식물 기준)
- **식물 관리 기능**
  - 식물 등록, 수정, 삭제
  - 이미지 업로드 및 타입 선택
- **사용자 프로필**
  - 닉네임, 사진 변경, 가입일 확인
- **커뮤니티**
  - 게시글 작성 및 열람
  - 게시자 정보(닉네임, 프로필 사진) 표시
- **Firebase 연동**
  - Authentication, Cloud Firestore, Firebase Storage

---

## 🛠 기술 스택

- **Flutter (3.29.3)** + Dart
- **Firebase**
  - Authentication
  - Cloud Firestore
  - Firebase Storage
- **Arduino**
  - 조도 센서
  - 토양 수분 센서
  - 온습도 센서 (DHT11)
  - 블루투스 모듈 (BLE CC2541)

---

## 🚀 팀 소개 - Team Zero

| 이름 | 역할 |
|------|------|
| 손창준 | Flutter 개발 / Firebase 연동 / Android Studio-Arduino간 연결 |
| 김세린 | 아두이노 설계 및 블루투스 송수신 구현 |
| 조알렉스 | UI/UX 디자인 및 화면 구현 |

---

> Made with 💚 by **Team Zero** – KHUTHON 2025
