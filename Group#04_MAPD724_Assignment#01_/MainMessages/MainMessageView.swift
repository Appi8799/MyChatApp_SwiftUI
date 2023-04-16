//
//  MainMessageView.swift
//  Group#04_MAPD724_Assignment#01_
//
//
//  Student Name & ID:
//      Ajay Shrivastav - 301284668
//      Apeksha Parmar - 301205325
//      Brijen Jayeshbhai Shah - 301271637
//
//  App Description  - MyChatApp
//      -This is a live chat app using various frameworks.
//
//  Created by
//      Apeksha Parmar on 2023-03-26.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase

struct RecentMessage: Identifiable {
    
    var id: String? { documentId }
    
    let documentId: String
    let text, email: String
    let fromId, toId, profileImageUrl: String
    let timestamp: Timestamp
    
    var username: String {
        email.components(separatedBy: "@").first ?? email
    }
    
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""
        self.toId = data[FirebaseConstants.toId] as? String ?? ""
        self.text = data[FirebaseConstants.text] as? String ?? ""
        self.profileImageUrl = data[FirebaseConstants.profileImageUrl] as? String ?? ""
        self.email = data[FirebaseConstants.email] as? String ?? ""
        self.timestamp = data[FirebaseConstants.timestamp] as? Timestamp ?? Timestamp(date: Date())
    }
    
}

class MainMessagesViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    @Published var isUserCurrentlyLoggedOut = true
    
    init() {
        
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut =
            FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        fetchCurrentUser()
            
        fetchRecentMessages()
        
        }
    
    @Published var recentMessages = [RecentMessage]()
    
    private func fetchRecentMessages() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { QuerySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen for recent messages: \(error)"
                    print(error)
                    return
                }
                
                QuerySnapshot?.documentChanges.forEach({ change in
                    let docId = change.document.documentID
                    
                    if let index = self.recentMessages.firstIndex(where: { rm in return rm.documentId == docId }) {
                        self.recentMessages.remove(at: index)
                    }
                    
                    
                    
                    self.recentMessages.insert(.init(documentId: docId, data: change.document.data()), at: 0)
                    
                    //self.recentMessages.append(.init(documentId: docId, data: change.document.data()))
                    
                })
            }
    }
    
        func fetchCurrentUser() {
            
            guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
                self.errorMessage = "Could not find firebase uid"
                return }
            
            FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
                if let error = error {
                    self.errorMessage = "failed to fetch current user: \(error)"
                print("Failed to fetch current user:", error)
                return
                }
                
                //self.errorMessage = "123"
                
                guard let data = snapshot?.data() else {
                    self.errorMessage = "No data found"
                    return }
                
                self.chatUser = .init(data: data)
                
//                let uid = data["uid"] as? String ?? ""
//                let email = data["email"] as? String ?? ""
//                let profileImageUrl = data["profileImageUrl"] as? String ?? ""
//                self.chatUser = ChatUser(uid: uid, email: email, profileImageUrl: profileImageUrl)
//
                //self.errorMessage = chatUser.profileImageUrl
                
                //self.errorMessage = "Data: \(data.description)"
                //print(data)
            }
        }
    
    
    func handleSignOut() {
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
}

struct MainMessagesView: View {
    
    @State var shouldShowLogOutOptions = false
    
    @ObservedObject private var vm = MainMessagesViewModel()
    
    @State var shouldNavigateToChatLogView = false
    
    var body: some View {
        NavigationView {
            
            VStack {
                //Text("CURRENT USER ID: \(vm.chatUser?.uid ?? "")")
               // Custom Navigation bar
                customNavBar
                messagesView
                
                NavigationLink("", isActive: $shouldNavigateToChatLogView) {
                    //Text("Chat log view")
                    ChatLogView(chatUser: self.chatUser)
                }
            }
            .overlay(
                newMessageButton, alignment: .bottom)
            .navigationBarHidden(true)
            //.navigationTitle("Main message view")
        }
    }
    
    private var customNavBar: some View {
        HStack(spacing: 16) {
            
            WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? "")).resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .clipped()
                .cornerRadius(50)
                .overlay(RoundedRectangle(cornerRadius: 44)
                    .stroke(Color(.label), lineWidth: 1)
                )
                .shadow(radius: 5)
            
//            Image(systemName: "person.fill")
//                .font(.system(size: 34, weight: .heavy))
            
            VStack(alignment: .leading, spacing: 4) {
                let email = vm.chatUser?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? ""
                Text(email)
                    .font(.system(size: 24, weight: .bold))
                
                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 14, height: 14)
                    Text("online")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.lightGray))
                }
            }
            
            Spacer()
            Button {
                shouldShowLogOutOptions.toggle()
            } label: {
                 Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
        }
        .padding()
        .actionSheet(isPresented: $shouldShowLogOutOptions) {
            .init(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [
                .destructive(Text("Sign Out"), action: {
                    print("Handle sign out")
                    vm.handleSignOut()
                }),
                .cancel()
            ])
        }
        .fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedOut, onDismiss: nil) {
            //Text("COVER")
            LoginView(didCompleteLoginProcess: {
                self.vm.isUserCurrentlyLoggedOut = false
                self.vm.fetchCurrentUser()
            })
        }
    }
    
    
    
    private var messagesView: some View {
        ScrollView {
            ForEach(vm.recentMessages) { recentMessage in
                VStack {
                    NavigationLink {
                        ChatLogView(chatUser: self.chatUser)
                    } label: {
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: recentMessage.profileImageUrl))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64, height: 64)
                                .clipped()
                                .cornerRadius(64)
                                .overlay(RoundedRectangle(cornerRadius: 64)
                                    .stroke(Color.black, lineWidth: 1))
                                .shadow(radius: 5)
                            
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(recentMessage.email)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(.label))
                                Text(recentMessage.text)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.darkGray))
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            
                            Text("1hr")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        
                    }
                    Divider()
                        .padding(.vertical, 8)
                }
                .padding(.horizontal)
                }
            .padding(.bottom, 50)
            }
    }
    
    @State var shouldShowNewMessageScreen = false
    
    private var newMessageButton: some View {
        Button {
            shouldShowNewMessageScreen.toggle()
        } label: {
            HStack {
                Spacer()
                Text("+ New Message")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .background(Color.blue)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 15)
        }
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
            //Text("New Message Screen"){
            CreateNewMessageView(didSelectNewUser: { user in
                print(user.email)
                self.shouldNavigateToChatLogView.toggle()
                self.chatUser = user
                
            })
        }
    }
    
    @State var chatUser: ChatUser?
}

struct MainMessageView_Previews : PreviewProvider {
    static var previews: some View {
        MainMessagesView()
            .preferredColorScheme(.dark)
        
        MainMessagesView()
    }
}


