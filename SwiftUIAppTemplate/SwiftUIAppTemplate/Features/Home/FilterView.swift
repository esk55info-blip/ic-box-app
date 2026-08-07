import SwiftUI

struct FilterView: View {
    @Binding var selectedType: String
    var onApply: () -> Void
    @Environment(\.dismiss) var dismiss
    
    // 🌟 جلب مدير القياسات الذكي
    @StateObject private var layout = AppLayoutManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("نوع المحتوى").font(.system(size: layout.isPad ? 16 : 13))) {
                    Picker("النوع", selection: $selectedType) {
                        Text("الكل").tag("الكل")
                        Text("أفلام").tag("أفلام")
                        Text("مسلسلات").tag("مسلسلات")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Button(action: {
                    onApply()
                    dismiss()
                }) {
                    Text("تطبيق")
                    // 🌟 تكبير خط الزر بالآيباد
                        .font(.system(size: layout.isPad ? 20 : 17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    // 🌟 تكبير مساحة الزر بالآيباد
                        .padding(layout.isPad ? 20 : 16)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("تصفية النتائج")
            .environment(\.layoutDirection, .rightToLeft)
        }
    }
}

