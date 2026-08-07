import SwiftUI
import PhotosUI

struct EditProfileScreen: View {
    @ObservedObject private var auth = FirebaseAuthManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var nameInput = ""
    @State private var bioInput = ""
    
    // متغيرات لاختيار الصورة من الاستوديو
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    @State private var statusMessage = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // الشريط العلوي للإغلاق
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 26)).foregroundColor(.white)
                    }
                    Spacer()
                    Text("تعديل الملف الشخصي").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                    Spacer()
                    Spacer().frame(width: 26)
                }
                .padding(.horizontal, 20).padding(.top, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        // 🖼️ دائرة اختيار الصورة من الاستوديو
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack {
                                if let data = selectedImageData, let uiImg = UIImage(data: data) {
                                    Image(uiImage: uiImg).resizable().scaledToFill()
                                        .frame(width: 90, height: 90).clipShape(Circle())
                                        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                                } else if let data = auth.currentUser?.profileImageData, let uiImg = UIImage(data: data) {
                                    Image(uiImage: uiImg).resizable().scaledToFill()
                                        .frame(width: 90, height: 90).clipShape(Circle())
                                        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                                } else {
                                    Circle().fill(Color.gray.opacity(0.3)).frame(width: 90, height: 90)
                                    Image(systemName: "camera.fill").font(.system(size: 24)).foregroundColor(.white)
                                }
                            }
                        }
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }
                        
                        Text("اضغط لتغيير الصورة الشخصية من المعرض").font(.system(size: 12)).foregroundColor(.gray)
                        
                        if !statusMessage.isEmpty {
                            Text(statusMessage).font(.system(size: 13, weight: .bold)).foregroundColor(.green)
                        }
                        
                        // الحقول النصية للتعديل
                        VStack(alignment: .leading, spacing: 6) {
                            Text("الاسم أو اللقب").font(.system(size: 12)).foregroundColor(.gray)
                            TextField("الاسم", text: $nameInput)
                                .padding().background(Color.white.opacity(0.08)).cornerRadius(10).foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("النبذة التعريفية (Bio)").font(.system(size: 12)).foregroundColor(.gray)
                            TextField("نبذة عنك...", text: $bioInput)
                                .padding().background(Color.white.opacity(0.08)).cornerRadius(10).foregroundColor(.white)
                        }
                        
                        // زر الحفظ
                        Button(action: {
                            auth.updateProfile(newName: nameInput, newBio: bioInput, imageData: selectedImageData)
                            statusMessage = "تم حفظ التعديلات بنجاح! ✅"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                dismiss()
                            }
                        }) {
                            Text("حفظ التعديلات")
                                .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding()
                                .background(Color.blue).cornerRadius(12)
                        }
                        .padding(.top, 10)
                        
                        // 🔑 زر نسيت كلمة المرور / تغييرها
                        Button(action: {
                            if let email = auth.currentUser?.email {
                                auth.resetPassword(email: email) { success, msg in
                                    statusMessage = msg
                                }
                            }
                        }) {
                            Text("إرسال رابط تغيير كلمة المرور للإيميل")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.yellow)
                        }
                        .padding(.top, 10)
                        
                    }
                    .padding(24)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            if let user = auth.currentUser {
                nameInput = user.displayName
                bioInput = user.bio
            }
        }
    }
}


