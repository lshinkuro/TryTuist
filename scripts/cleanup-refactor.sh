#!/usr/bin/env bash
# Hapus file lama yang sudah tidak dipakai setelah refactor.
# Aman dijalankan berkali-kali. Jalankan dari mana saja:  bash scripts/cleanup-refactor.sh
set -euo pipefail
cd "$(dirname "$0")/.."

# Refactor 1: navigasi (Coordinator/ViewController per screen → Router)
rm -rf Foundations/Coordinator Foundations/Dependency Features/TabBarFeature
rm -f App/Sources/AppCoordinator.swift Foundations/Utility/Sources/Utility/BaseViewController.swift

# Refactor 2: arsitektur (UDF + Data/Domain/Presentation)
rm -f Features/AuthenticationFeature/Sources/Common/AuthFormView.swift
rm -f Features/AuthenticationFeature/Sources/Common/AuthService.swift
rm -f Features/AuthenticationFeature/Sources/Onboarding/OnBoardingView.swift
rm -f Features/AuthenticationFeature/Sources/SignIn/SignInView.swift
rm -f Features/AuthenticationFeature/Sources/SignIn/SignInViewModel.swift
rm -f Features/AuthenticationFeature/Sources/SignUp/SignUpView.swift
rm -f Features/AuthenticationFeature/Sources/SignUp/SignUpViewModel.swift
rm -f Features/AuthenticationFeature/Sources/SplashScreen/SplashScreenView.swift
rm -f Features/CalenderFeature/Sources/Calender/CalenderView.swift
rm -f Features/FocuseFeature/Sources/FocuseModel.swift
rm -f Features/FocuseFeature/Sources/Focuses/FocusesView.swift
rm -f Features/HomeFeature/Sources/Home/HomeView.swift
rm -f Features/HomeFeature/Sources/Home/HomeViewModel.swift
rm -f Features/HomeFeature/Sources/Home/ProductDetailView.swift
rm -f Features/HomeFeature/Sources/Home/Components/MenuAdsView.swift
rm -f Features/HomeFeature/Sources/Home/Components/MenuSectionView.swift
rm -f Features/HomeFeature/Sources/Home/Components/MissionCardsView.swift
rm -f Features/HomeFeature/Sources/Home/Components/ProductCardView.swift
rm -f Features/HomeFeature/Sources/Home/Components/TopBannerView.swift
rm -f Features/ProfileFeature/Sources/Profile/ProfileView.swift
rm -f Foundations/Utility/Sources/Utility/BaseViewModel.swift

# Refactor 3: katalog F&B (Beranda + Menu), Kalender dihapus
rm -rf Features/CalenderFeature
rm -f Features/HomeFeature/Sources/Presentation/Home/Components/ContactListView.swift
rm -f Features/HomeFeature/Sources/Presentation/Home/Components/MenuAdsView.swift
rm -f Features/HomeFeature/Sources/Presentation/Home/Components/MenuSectionView.swift
rm -f Features/HomeFeature/Sources/Presentation/Home/Components/ProductCardView.swift
rm -f Features/HomeFeature/Sources/Presentation/Home/Components/TopBannerView.swift
rm -f Features/HomeFeature/Sources/Domain/Entity/Contact.swift
rm -f Features/HomeFeature/Sources/Domain/Repository/HomeRepository.swift
rm -f Features/HomeFeature/Sources/Domain/UseCase/GetHomeContentUseCase.swift
rm -f Features/HomeFeature/Sources/Data/DTO/HomeDTOs.swift
rm -f Features/HomeFeature/Sources/Data/Mapper/HomeMapper.swift
rm -f Features/HomeFeature/Sources/Data/DataSource/HomeRemoteDataSource.swift
rm -f Features/HomeFeature/Sources/Data/DataSource/ContactLocalDataSource.swift
rm -f Features/HomeFeature/Sources/Data/Repository/DefaultHomeRepository.swift

# Bersihkan folder kosong yang tersisa.
find Features Foundations -type d -empty -delete

echo "Selesai. Jalankan 'make gen' untuk generate ulang project."
