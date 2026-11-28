import SwiftUI

/// «О канале»: расписание, баннер, описание, ссылки. Пустые части не показываются.
struct ChannelAboutView: View {
    let channel: Channel
    let about: ChannelAbout
    let schedule: [ScheduledStream]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            if !schedule.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    SectionHeader(title: "Расписание", subtitle: "Нажмите «Напомнить» — пришлём уведомление")
                    ScheduleStripView(items: schedule, showsChannel: false)
                }
            }
            if !about.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    SectionHeader(title: "О канале")
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        if let banner = about.bannerUrl {
                            AsyncImage(url: banner) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                channel.tone.surface
                            }
                            .frame(maxWidth: .infinity)
                            .aspectRatio(4, contentMode: .fit)
                            .clipShape(.rect(cornerRadius: Radius.m))
                        }
                        if !about.description.isEmpty {
                            Text(about.description)
                                .font(.brandBody)
                                .foregroundStyle(Palette.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if !about.links.isEmpty {
                            FlowLinks(links: about.links)
                        }
                    }
                    .padding(Spacing.m)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.surface, in: .rect(cornerRadius: Radius.l))
                }
            }
        }
    }
}

/// Ссылки канала: кнопки-капсулы, открываются в браузере.
private struct FlowLinks: View {
    let links: [ChannelAbout.Link]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(links, id: \.url) { link in
                    if let url = URL(string: link.url) {
                        Link(destination: url) {
                            Text(link.title)
                                .font(.brandCaption)
                                .padding(.horizontal, Spacing.s)
                                .frame(minHeight: 36)
                                .background(Palette.accent.opacity(0.12), in: .capsule)
                        }
                    }
                }
            }
        }
    }
}
