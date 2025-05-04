import Foundation
import FirebaseFirestore
import FirebaseFunctions
import FirebaseAuth

class UserAnalyticsService {
    // 싱글톤 인스턴스
    static let shared = UserAnalyticsService()
    
    private let db = Firestore.firestore()
    // 리전 명시 (예: "asia-northeast1") - 실제 프로젝트 리전에 맞게 수정
    private let functions = Functions.functions(region: "asia-northeast1")
    
    private init() {}
    
    // MARK: - 데이터 조회 메서드
    
    /// 사용자의 운동 분석 데이터를 가져오는 메서드
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - completion: 완료 핸들러 (분석 데이터와 에러)
    func getUserAnalytics(userId: String, completion: @escaping (UserAnalytics?, Error?) -> Void) {
        let docRef = db.collection("UserAnalytics").document(userId)
        
        docRef.getDocument { (document, error) in
            if let error = error {
                print("Error getting analytics: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let document = document, document.exists else {
                print("No analytics data exists for user: \(userId)")
                completion(nil, nil) // 오류 없이 분석 데이터가 없는 경우
                return
            }
            
            do {
                let analytics = try document.data(as: UserAnalytics.self)
                completion(analytics, nil)
            } catch {
                print("Error decoding analytics data: \(error.localizedDescription)")
                completion(nil, error)
            }
        }
    }
    
    // MARK: - 데이터 업데이트 메서드
    
    /// 사용자의 운동 분석 데이터를 수동으로 업데이트 요청하는 메서드
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - completion: 완료 핸들러 (성공 여부와 에러)
    func updateUserAnalytics(userId: String, completion: @escaping (Bool, Error?) -> Void) {
        print("Analytics update requested for user ID: \(userId)")
        
        // 현재 인증된 사용자 확인
        guard let currentUser = Auth.auth().currentUser else {
            let error = NSError(domain: "AnalyticsService", code: 401, 
                                userInfo: [NSLocalizedDescriptionKey: "인증된 사용자가 없습니다."])
            completion(false, error)
            return
        }
        
        // 백엔드 함수 호출을 위한 데이터 준비
        let data: [String: Any] = ["userId": userId]
        
        // 함수 이름과 리전 확인
        let functionName = "updateUserAnalytics"
        let regionName = "asia-northeast1"
        print("Calling function \(functionName) in region \(regionName)")
        
        // 디버깅을 위해 함수 호출 전 데이터 출력
        print("Sending data to function: \(data)")
        
        // Firebase 인증 토큰 설정
        let functions = Functions.functions(region: regionName)
        
        // Firebase Functions 호출
        functions.httpsCallable(functionName).call(data) { [weak self] result, error in
            if let error = error {
                print("Function call error: \(error)")
                if let nsError = error as NSError? {
                    print("Function call error details: \(nsError.domain), \(nsError.code), \(nsError.userInfo)")
                }
                completion(false, error)
                return
            }
            
            if let resultData = result?.data as? [String: Any] {
                print("Function response: \(resultData)")
                
                // success 값이 있으면 사용, 없거나 Bool이 아니면 false 반환
                if let success = resultData["success"] as? Bool {
                    completion(success, nil)
                } else {
                    print("Success key not found in response or not a boolean")
                    completion(false, nil)
                }
            } else {
                print("Unexpected response format. Raw result: \(String(describing: result?.data))")
                completion(false, NSError(domain: "AnalyticsService", code: 500, 
                                        userInfo: [NSLocalizedDescriptionKey: "서버 응답 형식이 잘못되었습니다."]))
            }
        }
    }
    
    // MARK: - 데이터 변환 유틸리티 메서드
    
    /// 운동 부위 분포 데이터를 차트 데이터 포맷으로 변환하는 메서드
    /// - Parameter distribution: 부위별 분포 딕셔너리
    /// - Returns: 차트용 데이터 배열
    func getDistributionChartData(from distribution: ExerciseDistribution) -> [(String, Double)] {
        return distribution.map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 } // 분포 비율이 높은 순서로 정렬
    }
    
    /// 선호 운동에서 무게가 가장 높은 Top N 운동 정보를 반환하는 메서드
    /// - Parameter favoriteExercises: 선호 운동 목록
    /// - Parameter count: 반환할 운동 수
    /// - Returns: 무게 기준으로 정렬된 운동 목록
    func getTopExercisesByWeight(from favoriteExercises: [FavoriteExercise], count: Int = 3) -> [FavoriteExercise] {
        return favoriteExercises
            .sorted { $0.avgWeight > $1.avgWeight }
            .prefix(count)
            .map { $0 }
    }
    
    /// 팔로잉 사용자 대비 운동 빈도 비교 문자열을 반환하는 메서드
    /// - Parameter comparison: 팔로잉 비교 데이터
    /// - Returns: 비교 결과 문자열
    func getFollowingComparisonString(from comparison: FollowingComparison) -> String {
        let diff = comparison.user - comparison.followingAvg
        
        if diff > 0 {
            return "あなたはフォロー中のユーザーより週に\(diff)回多く運動しています"
        } else if diff < 0 {
            return "あなたはフォロー中のユーザーより週に\(abs(diff))回少なく運動しています"
        } else {
            return "あなたはフォロー中のユーザーと同じくらい運動しています"
        }
    }
} 