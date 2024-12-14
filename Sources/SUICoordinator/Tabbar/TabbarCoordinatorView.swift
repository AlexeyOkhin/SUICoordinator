//
//  TabbarCoordinatorView.swift
//
//  Copyright (c) Andres F. Lozano
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import SwiftUI
import Foundation

struct TabbarCoordinatorView<PAGE: TabbarPage>: View {
    
    typealias BadgeItem = (value: String?, page: PAGE)
    
    // ---------------------------------------------------------------------
    // MARK: Properties
    // ---------------------------------------------------------------------
    
    @StateObject var viewModel: TabbarCoordinator<PAGE>
    @State var badges = [BadgeItem]()
    @State var pages = [PAGE]()
    @State var currentPage: PAGE
    
    // ---------------------------------------------------------------------
    // MARK: View
    // ---------------------------------------------------------------------
    
    public var body: some View {
        TabView(selection: tabSelection()){
            ForEach(pages, id: \.id, content: makeTabView)
        }
        .onReceive(viewModel.$pages) { pages in
            self.pages = pages
            badges = pages.map { (nil, $0) }
        }
        .onReceive(viewModel.$currentPage) { page in
            currentPage = page
        }
        .onReceive(viewModel.setBadge) { (value, page) in
            guard let index = getBadgeIndex(page: page) else { return }
            badges[index].value = value
        }
    }
    
    // ---------------------------------------------------------------------
    // MARK: Helper funcs
    // ---------------------------------------------------------------------
    
    @ViewBuilder
    func makeTabView(page: PAGE) -> some View {
        if let item = viewModel.getCoordinator(with: page.position) {
            AnyView( item.getView() )
                .tabItem {
                    Label(
                        title: { AnyView(page.title) },
                        icon: { AnyView(page.icon) } )
                }
                .badge(getBadge(page: page)?.value)
                .tag(page)
        }
    }
    
    private func getBadge(page: PAGE) -> BadgeItem? {
        guard let index = getBadgeIndex(page: page) else {
            return nil
        }
        return badges[index]
    }
    
    private func getBadgeIndex(page: PAGE) -> Int? {
        badges.firstIndex(where: { $0.1 == page })
    }
}


extension TabbarCoordinatorView {
    
    private func tabSelection() -> Binding<PAGE> {
        Binding {
            currentPage
        } set: { [weak viewModel] tappedTab in
            if tappedTab == currentPage {
                Task(priority: .high) { await viewModel?.popToRoot() }
            }
            viewModel?.currentPage = tappedTab
        }
    }
}
