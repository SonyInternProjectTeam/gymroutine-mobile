import SwiftUI

struct GroupSearchView: View {
    @StateObject private var viewModel = GroupSearchViewModel()
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 검색 바
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("グループを検索", text: $searchText)
                        .onSubmit {
                            viewModel.searchGroups(query: searchText)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            viewModel.clearSearch()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // 태그 필터
                if !viewModel.availableTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.availableTags, id: \.self) { tag in
                                Button(action: {
                                    viewModel.toggleTag(tag)
                                }) {
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(viewModel.selectedTags.contains(tag) ? Color(.systemBlue) : Color(.systemGray5))
                                        .foregroundColor(viewModel.selectedTags.contains(tag) ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding()
            
            Divider()
            
            // 검색 결과
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("グループを検索中...")
                    Spacer()
                }
            } else if let errorMessage = viewModel.errorMessage {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding()
            } else if viewModel.searchResults.isEmpty && !viewModel.lastSearchedQuery.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("「\(viewModel.lastSearchedQuery)」に一致するグループがありません")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Text("別のキーワードで検索してみてください")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
            } else if viewModel.searchResults.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "person.3")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("公開グループを検索")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("キーワードを入力してグループを探してみましょう")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.searchResults) { group in
                            GroupSearchResultCell(group: group, viewModel: viewModel)
                        }
                    }
                    .padding()
                }
            }
        }
        // Hidden NavigationLink for programmatic navigation after joining a group
        .background(
            NavigationLink(destination: viewModel.successfullyJoinedGroup != nil ? 
                          GroupDetailView(group: viewModel.successfullyJoinedGroup!, isNewlyJoined: true) : nil,
                           isActive: Binding(
                            get: { viewModel.successfullyJoinedGroup != nil },
                            set: { isActive in if !isActive { viewModel.successfullyJoinedGroup = nil } }
                           ))
                             { EmptyView() }
                .hidden()
        )
        .navigationTitle("グループ検索")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.refreshGroups()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline)
                }
                .disabled(viewModel.isLoading)
            }
        }
        .onChange(of: viewModel.selectedTags) { _ in
            if !searchText.isEmpty {
                viewModel.searchGroups(query: searchText)
            }
        }
    }
}

struct GroupSearchResultCell: View {
    let group: GroupModel
    @ObservedObject var viewModel: GroupSearchViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NavigationLink(destination: GroupDetailView(group: group)) {
                HStack(spacing: 12) {
                    // 그룹 이미지
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBlue).opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "person.3.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(group.name)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if group.isPrivate {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }


                        if !group.isPrivate {
                            HStack {
                                Spacer()
                                if viewModel.myGroupIds.contains(group.id ?? "") || viewModel.joinedGroupIds.contains(group.id ?? "") {
                                    Text("参加済み")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 10)
                                        .background(Color.green.opacity(0.1))
                                        .clipShape(Capsule())
                                } else {
                                    Button(action: {
                                        if let groupId = group.id {
                                            viewModel.joinPublicGroup(group: group)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "person.badge.plus")
                                            Text("参加")
                                        }
                                        .font(.callout)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .frame(minWidth: 100)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                    }
                                    .disabled(viewModel.isJoiningGroup)
                                }
                            }
                            .padding(.top, 6)
                        }
                        
                        if let description = group.description, !description.isEmpty {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        

                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "person.2")
                                    .font(.caption)
                                Text("\(group.memberCount)명")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if !group.tags.isEmpty {
                                HStack(spacing: 4) {
                                    ForEach(group.tags.prefix(2), id: \.self) { tag in
                                        Text("#\(tag)")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color(.systemBlue).opacity(0.1))
                                            .foregroundColor(.accentColor)
                                            .clipShape(Capsule())
                                    }
                                    
                                    if group.tags.count > 2 {
                                        Text("+\(group.tags.count - 2)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    NavigationView {
        GroupSearchView()
    }
} 