//
//  HomeViewModel.swift
//  HomeFeature
//
import Foundation
import CoreDataManager
import Utility

struct TopBannerItem: Equatable {
    let imageName: String
    let title: String
    let subtitle: String
    let bgImageName: String
}

final class HomeViewModel: BaseViewModel {
    @Published private(set) var users: [UserModel] = []

    let banners: [TopBannerItem] = [
        .init(imageName: "onboarding-1", title: "Manage your tasks", subtitle: "You can easily manage all of your daily tasks in DoMe for free", bgImageName: "bg-1"),
        .init(imageName: "onboarding-2", title: "Create daily routine", subtitle: "In Uptodo  you can create your personalized routine to stay productive", bgImageName: "bg-2"),
        .init(imageName: "onboarding-3", title: "Orgonaize your tasks", subtitle: "You can organize your daily tasks by adding your tasks into separate categories", bgImageName: "bg-3")
    ]

    private let coreDataManager = CoreDataManager.shared

    func loadData() {
        do {
            let newItemProperties: [String: Any] = [
                "id": "1",
                "avatar": "avatar",
                "userName": "bagus",
                "email": "bagus@gmail.com",
                "phoneNumber": "0857753810923"
            ]
            try coreDataManager.create(entity: UserModel.self, properties: newItemProperties)
        } catch {
            print("Failed to add to Quick Send: \(error)")
        }

        do {
            users = try coreDataManager.fetch(entity: UserModel.self, fetchLimit: 5)
        } catch {
            print("Failed to fetch contacts: \(error.localizedDescription)")
        }
    }
}
