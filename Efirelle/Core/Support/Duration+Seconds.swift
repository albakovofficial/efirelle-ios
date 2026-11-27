extension Duration {
    /// Длительность в секундах как `Double` — для слайдеров и долей шкалы.
    var inSeconds: Double {
        let (seconds, attoseconds) = components
        return Double(seconds) + Double(attoseconds) / 1e18
    }
}
