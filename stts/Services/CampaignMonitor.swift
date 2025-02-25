//
//  CampaignMonitor.swift
//  stts
//

import Foundation
import Kanna

class CampaignMonitor: Service {
    private enum Status: String, CaseIterable {
        case available
        case unavailable
        case informational
        case monitored
        case identified
        case investigating
        case degraded
        case maintenance

        var serviceStatus: ServiceStatus {
            switch self {
            case .available:
                return .good
            case .unavailable:
                return .major
            case .informational, .monitored, .identified:
                return .notice
            case .investigating, .degraded:
                return .minor
            case .maintenance:
                return .maintenance
            }
        }
    }

    let name = "Campaign Monitor"
    let url = URL(string: "https://status.campaignmonitor.com")!

    override func updateStatus(callback: @escaping (BaseService) -> Void) {
        loadData(with: url) { [weak self] data, _, error in
            guard let strongSelf = self else { return }
            defer { callback(strongSelf) }
            guard let data = data else { return strongSelf._fail(error) }

            guard let doc = try? HTML(html: data, encoding: .utf8) else {
                return strongSelf._fail("Couldn't parse response")
            }

            let statuses: [(ServiceStatus, String?)] = doc.css(".status-list-component-status-text").map { element in
                for status in Status.allCases {
                    if element.className?.contains("component-\(status.rawValue)") == true {
                        return (
                            status.serviceStatus,
                            element.innerHTML?.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    }
                }

                return (.undetermined, nil)
            }

            guard let worstStatus = statuses.max(by: { $0.0 < $1.0 }) else {
                return strongSelf._fail("Unexpected response")
            }

            self?.status = worstStatus.0
            self?.message = worstStatus.1 ?? "Unexpected response"
        }
    }
}
