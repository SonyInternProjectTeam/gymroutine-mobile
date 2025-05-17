//
//  TemplateService.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/05/12.
//

import Foundation
import FirebaseFirestore

class TemplateService {
    private let db = Firestore.firestore()
    
    /// 모든 워크아웃 템플릿을 가져옴
    func getAllTemplates() async -> Result<[WorkoutTemplate], Error> {
        do {
            print("🔍 [TemplateService] 모든 템플릿 로드 시작")
            let snapshot = try await db.collection("Templates").getDocuments()
            print("📊 [TemplateService] 템플릿 문서 \(snapshot.documents.count)개 가져옴")
            
            var successCount = 0
            var failedCount = 0
            let templates = snapshot.documents.compactMap { document -> WorkoutTemplate? in
                do {
                    let template = try document.data(as: WorkoutTemplate.self)
                    successCount += 1
                    return template
                } catch {
                    failedCount += 1
                    print("⛔️ [TemplateService] 템플릿 디코딩 오류 (\(document.documentID)): \(error)")
                    
                    // 더 구체적인 오류 추적을 위한 데이터 덤프
                    print("📝 [TemplateService] 실패한 문서 ID: \(document.documentID)")
                    print("📝 [TemplateService] 실패한 문서 필드: \(document.data().keys)")
                    
                    return nil
                }
            }
            
            print("✅ [TemplateService] 템플릿 로드 완료: 성공 \(successCount)개, 실패 \(failedCount)개")
            return .success(templates)
        } catch {
            print("⛔️ [TemplateService] 템플릿 로드 중 오류 발생: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    /// 프리미엄 여부로 템플릿 필터링
    func getTemplates(isPremium: Bool) async -> Result<[WorkoutTemplate], Error> {
        do {
            print("🔍 [TemplateService] isPremium=\(isPremium) 템플릿 로드 시작")
            let snapshot = try await db.collection("Templates")
                .whereField("isPremium", isEqualTo: isPremium)
                .getDocuments()
            
            print("📊 [TemplateService] isPremium=\(isPremium) 템플릿 문서 \(snapshot.documents.count)개 가져옴")
            
            var successCount = 0
            var failedCount = 0
            let templates = snapshot.documents.compactMap { document -> WorkoutTemplate? in
                do {
                    let template = try document.data(as: WorkoutTemplate.self)
                    successCount += 1
                    return template
                } catch {
                    failedCount += 1
                    print("⛔️ [TemplateService] 템플릿 디코딩 오류 (\(document.documentID)): \(error)")
                    
                    // 더 구체적인 오류 추적을 위한 데이터 덤프
                    print("📝 [TemplateService] 실패한 문서 ID: \(document.documentID)")
                    print("📝 [TemplateService] 실패한 문서 필드: \(document.data().keys)")
                    
                    return nil
                }
            }
            
            print("✅ [TemplateService] isPremium=\(isPremium) 템플릿 로드 완료: 성공 \(successCount)개, 실패 \(failedCount)개")
            return .success(templates)
        } catch {
            print("⛔️ [TemplateService] 템플릿 로드 중 오류 발생: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    /// 레벨별 템플릿 필터링
    func getTemplatesByLevel(level: String) async -> Result<[WorkoutTemplate], Error> {
        do {
            print("🔍 [TemplateService] level=\(level) 템플릿 로드 시작")
            let snapshot = try await db.collection("Templates")
                .whereField("level", isEqualTo: level)
                .getDocuments()
            
            print("📊 [TemplateService] level=\(level) 템플릿 문서 \(snapshot.documents.count)개 가져옴")
            
            var successCount = 0
            var failedCount = 0
            let templates = snapshot.documents.compactMap { document -> WorkoutTemplate? in
                do {
                    let template = try document.data(as: WorkoutTemplate.self)
                    successCount += 1
                    return template
                } catch {
                    failedCount += 1
                    print("⛔️ [TemplateService] 템플릿 디코딩 오류 (\(document.documentID)): \(error)")
                    
                    // 더 구체적인 오류 추적을 위한 데이터 덤프
                    print("📝 [TemplateService] 실패한 문서 ID: \(document.documentID)")
                    print("📝 [TemplateService] 실패한 문서 필드: \(document.data().keys)")
                    
                    return nil
                }
            }
            
            print("✅ [TemplateService] level=\(level) 템플릿 로드 완료: 성공 \(successCount)개, 실패 \(failedCount)개")
            return .success(templates)
        } catch {
            print("⛔️ [TemplateService] 템플릿 로드 중 오류 발생: \(error.localizedDescription)")
            return .failure(error)
        }
    }
} 