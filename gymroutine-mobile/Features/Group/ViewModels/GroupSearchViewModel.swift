import Foundation
import SwiftUI

@MainActor
final class GroupSearchViewModel: ObservableObject {
    @Published var searchResults: [GroupModel] = []
    @Published var allGroups: [GroupModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var availableTags: [String] = []
    @Published var selectedTags: [String] = []
    @Published var lastSearchedQuery: String = ""
    
    private let groupService = GroupService()
    
    init() {
        loadAvailableTags()
        loadAllPublicGroups()
    }
    
    /// 모든 공개 그룹을 로드 (초기 로드)
    func loadAllPublicGroups() {
        Task {
            isLoading = true
            errorMessage = nil
            
            let result = await groupService.getAllPublicGroups()
            
            isLoading = false
            
            switch result {
            case .success(let groups):
                allGroups = groups
                print("✅ [GroupSearchViewModel] 모든 공개 그룹 로드 완료: \(groups.count)개")
                
            case .failure(let error):
                print("⛔️ [GroupSearchViewModel] 공개 그룹 로드 실패: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                allGroups = []
            }
        }
    }
    
    /// 프론트엔드에서 그룹 검색 (SnsView 참고)
    func searchGroups(query: String) {
        lastSearchedQuery = query
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // 프론트엔드에서 필터링
        var filteredGroups = allGroups.filter { group in
            // 그룹 이름으로 검색
            let nameMatch = group.name.lowercased().contains(trimmedQuery)
            
            // 그룹 설명으로 검색
            let descriptionMatch = group.description?.lowercased().contains(trimmedQuery) ?? false
            
            // 태그로 검색
            let tagMatch = group.tags.contains { tag in
                tag.lowercased().contains(trimmedQuery)
            }
            
            return nameMatch || descriptionMatch || tagMatch
        }
        
        // 선택된 태그로 추가 필터링
        if !selectedTags.isEmpty {
            filteredGroups = filteredGroups.filter { group in
                selectedTags.allSatisfy { selectedTag in
                    group.tags.contains(selectedTag)
                }
            }
        }
        
        searchResults = filteredGroups
        print("✅ [GroupSearchViewModel] 검색 완료: '\(query)' -> \(filteredGroups.count)개 결과")
    }
    
    /// 검색 결과 초기화
    func clearSearch() {
        searchResults = []
        lastSearchedQuery = ""
        errorMessage = nil
    }
    
    /// 태그 토글
    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.removeAll { $0 == tag }
        } else {
            selectedTags.append(tag)
        }
    }
    
    /// 사용 가능한 태그 로드
    func loadAvailableTags() {
        // 일반적인 운동 관련 태그들
        availableTags = [
            "근력운동", "유산소", "다이어트", "벌크업", "헬스", "홈트레이닝",
            "요가", "필라테스", "러닝", "사이클링", "수영", "크로스핏"
        ]
    }
    
    /// 그룹 목록 새로고침
    func refreshGroups() {
        loadAllPublicGroups()
    }
} 