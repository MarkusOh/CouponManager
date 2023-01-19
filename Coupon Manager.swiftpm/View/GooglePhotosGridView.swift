//
//  File.swift
//  
//
//  Created by Seungsub Oh on 2023/01/01.
//

import SwiftUI

struct GooglePhotosGridView: View {
    var googlePhotoItems: [GooglePhotoItem]
    let endOfGridAction: () -> Void
    let isForPreview: Bool
    
    @Binding var error: Error?
    @Binding var isPresented: Bool
    
    init(googlePhotoItems: [GooglePhotoItem], endOfGridAction: @escaping () -> Void, isForPreview: Bool = false, error: Binding<Error?>, isPresented: Binding<Bool>) {
        self.googlePhotoItems = googlePhotoItems
        self.endOfGridAction = endOfGridAction
        self.isForPreview = isForPreview
        self._error = error
        self._isPresented = isPresented
    }
    
    func photoThumbnailUrl(from url: URL) -> URL {
        if isForPreview {
            return url
        } else {
            return URL(string: url.absoluteString.appending("=w400-h400-c"))!
        }
    }
    
    @State private var imageSize: Double = 120.0
    @State private var spacing: Double = 3.0
    @State private var itemsPerRow: Int = 3
    
    @State private var selectedPhoto: UIImage?
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(geo.size.width / Double(itemsPerRow)), spacing: 0), count: itemsPerRow), spacing: 0) {
                    ForEach(Array(googlePhotoItems.enumerated()), id: \.element.id) { (index, photo) in
                        HStack {
                            NavigationLink(destination: {
                                BarcodeSelectionView(localImage: nil, url: photo.baseUrl, error: $error, isPresented: $isPresented)
                            }, label: {
                                AsyncImage(url: photoThumbnailUrl(from: photo.baseUrl), content: { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .imageIconModifier(imageWidth: imageSize)
                                }, placeholder: {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .foregroundColor(.gray.opacity(0.3))
                                        .scaledToFit()
                                        .imageIconModifier(imageWidth: imageSize)
                                })
                            })
                            .padding(.bottom, spacing / 2)
                            .onAppear {
                                guard index == googlePhotoItems.count - 1 else {
                                    return
                                }
                                
                                endOfGridAction()
                            }
                        }
                    }
                }
            }
            .onAppear {
                itemsPerRow = Int(geo.size.width / imageSize)
                let leftOver = geo.size.width - ((Double(itemsPerRow) - 1) * spacing + Double(itemsPerRow) * imageSize)
                let offset = leftOver / Double(itemsPerRow)
                imageSize += offset
            }
        }
    }
}

struct GooglePhotosGridView_Previews: PreviewProvider {
    static var mockData: [GooglePhotoItem] {
        let jsonString =
        """
        {
            "mediaItems": [
                {
                    "id": "123456",
                    "baseUrl": "https://cdn.pixabay.com/photo/2022/01/03/01/00/ruins-6911495_960_720.jpg",
                    "mimeType": "jpg",
                    "filename": "something1"
                },
                {
                    "id": "123457",
                    "baseUrl": "https://cdn.pixabay.com/photo/2022/12/16/12/59/christmas-7659606_960_720.jpg",
                    "mimeType": "jpg",
                    "filename": "something2"
                },
                {
                    "id": "123458",
                    "baseUrl": "https://cdn.pixabay.com/photo/2022/01/03/01/00/ruins-6911495_960_720.jpg",
                    "mimeType": "jpg",
                    "filename": "something1"
                },
                {
                    "id": "123459",
                    "baseUrl": "https://cdn.pixabay.com/photo/2022/12/16/12/59/christmas-7659606_960_720.jpg",
                    "mimeType": "jpg",
                    "filename": "something2"
                },
                {
                    "id": "123400",
                    "baseUrl": "https://cdn.pixabay.com/photo/2022/01/03/01/00/ruins-6911495_960_720.jpg",
                    "mimeType": "jpg",
                    "filename": "something1"
                },
                {
                    "id": "123401",
                    "baseUrl": "https://cdn.pixabay.com/photo/2022/12/16/12/59/christmas-7659606_960_720.jpg",
                    "mimeType": "jpg",
                    "filename": "something2"
                }
            ], "nextPageToken": "nothing here!"
        }
        """
        
        let dataStructure = try! JSONDecoder().decode(GooglePhotosStructure.self, from: jsonString.data(using: .utf8)!)
        let mediaItems = dataStructure.mediaItems!

        return mediaItems
    }

    static var previews: some View {
        GooglePhotosGridView(googlePhotoItems: mockData, endOfGridAction: {

        }, isForPreview: true, error: .constant(nil), isPresented: .constant(true))
    }
}

fileprivate struct ImageIconModifier: ViewModifier {
    var imageWidth: Double
    
    func body(content: Content) -> some View {
        content
            .frame(width: imageWidth, height: imageWidth)
            .clipShape(Rectangle())
    }
}

extension View {
    fileprivate func imageIconModifier(imageWidth: Double) -> some View {
        self.modifier(ImageIconModifier(imageWidth: imageWidth))
    }
}
