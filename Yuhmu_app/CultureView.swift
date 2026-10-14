import SwiftUI

/// Sección de preservación cultural de Ixtenco, Tlaxcala.
/// Para agregar contenido nuevo, añade un elemento a `sections`.
struct CultureSection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let body: String
}

struct CultureView: View {
    private let sections: [CultureSection] = [
        CultureSection(title: "Sobre nosotros", icon: "heart.fill",
            body: "Cuando una lengua muere, una forma de ver al mundo desaparece para siempre. En Ixtenco innovamos digitalmente para conectar la sabiduría de los sabios hablantes con las nuevas generaciones, manteniendo vivo el orgullo Yumhu.\n\n#LenguaYumhu #Libertad"),
        CultureSection(title: "Misión", icon: "target",
            body: "Preservar y revitalizar la lengua Yumhu en Ixtenco, Tlaxcala, mediante el desarrollo de herramientas tecnológicas interactivas y accesibles que conecten el conocimiento de los hablantes con el interés digital de las nuevas generaciones, promoviendo el orgullo por la identidad cultural."),
        CultureSection(title: "Visión", icon: "eye.fill",
            body: "Ser una plataforma digital de aprendizaje lingüístico y cultural que sirva de referencia en la región, logrando detener la pérdida de la lengua Yumhu, además de expandir nuestra tecnología hacia la preservación de otras lenguas indígenas en peligro de extinción, inspirando un movimiento de difusión del patrimonio originario a través de la innovación digital."),
        CultureSection(title: "Nuestros hablantes", icon: "person.3.fill",
            body: "Concepción Verdad Gaspar, de 80 años, creció escuchando y hablando Yuhmu en casa. Reconoce el valor y la belleza de su lengua, a pesar de la discriminación que vivió en su infancia.\n\nManuel Mexicano trabajó como albañil y campesino; hoy comparte sus conocimientos en la Universidad Intercultural de Tlaxcala y nos enseñó la importancia de la pronunciación.\n\nJuan Cajero nos recuerda que la lengua es parte de las tradiciones, la historia y la identidad de la comunidad, y que necesita espacios donde seguir hablándose."),
        CultureSection(title: "Aliado lingüístico", icon: "text.book.closed.fill",
            body: "Rafael Alarcón Montero, cronista y asesor lingüístico, colabora con Zentemi como guía en el desarrollo de los contenidos en Yuhmu: revisa y verifica la escritura y orienta sobre el uso adecuado de la lengua.")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MascotView(size: 100)
                Text("Cultura Yuhmu").font(.system(size: 28, weight: .heavy)).foregroundColor(Brand.purple)
                Text("Ixtenco, Tlaxcala").font(.subheadline).foregroundColor(.gray)

                ForEach(sections) { s in
                    VStack(alignment: .leading, spacing: 8) {
                        Label(s.title, systemImage: s.icon)
                            .font(.system(size: 18, weight: .heavy)).foregroundColor(Brand.magenta)
                        Text(s.body).font(.system(size: 15)).foregroundColor(Brand.deepPurple)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
                }
                Text("Un proyecto de Zentemi").font(.footnote).foregroundColor(.gray)
            }
            .padding()
        }
        .background(Brand.cream.ignoresSafeArea())
        .navigationBarTitle("Cultura", displayMode: .inline)
    }
}
