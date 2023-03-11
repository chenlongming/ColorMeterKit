import Foundation
import CoreBluetooth
import RxSwift


public class CMKit: NSObject {
    public var manager: CBCentralManager { connector.manager }
    
    public var isScanning: Bool { connector.manager.isScanning }
    
    public var connecting: CBPeripheral? { connector.connecting }
    
    public var connected: CBPeripheral? { connector.connected }
    
    /// observe bluetooth state update
    public var stateObservable: Observable<CMState> { connector.statePublish.asObservable() }
    
    public var waitingMeasure = false
    
    var connector: Connector!
    
    override init() {
        super.init()
        self.connector = Connector(queue: .global(), options: nil)
    }
    
    
    public init(queue: DispatchQueue = .global(), options: [String: Any]? = nil) {
        super.init()
        self.connector = Connector(queue: queue, options: options)
    }
    
    
    // MARK: - scan and connection
    
    /// start scan peripheral
    /// ```
    /// var scanDisposable: Disposable?
    /// var cm = CMKit()
    ///
    /// func scan() {
    ///     if !cm.isScanning {
    ///         cm.startScan()
    ///         scanDisposable = cm.observeScanned().subscribe(onNext: { state in
    ///             if peripheral = state.peripheral {
    ///                 // todo ...
    ///             }
    ///         })
    ///     }
    /// }
    ///
    /// func stop() {
    ///     if cm.isScanning {
    ///         cm.stopScan()
    ///         scanDisposable?.dispose()
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter options: [Peripheral Scanning Options](https://developer.apple.com/documentation/corebluetooth/cbcentralmanager/peripheral_scanning_options)
    public func startScan(options: [String: Any]? = nil) {
        connector.startScan(options: options)
    }
    
    
    /// stop scanning
    public func stopScan() {
        connector.stopScan()
    }
    
    /// connect to peripheral
    ///
    /// - Parameter peripheral: `CBPeripheral` connect  peripheral
    /// - Parameter options: [Peripheral Connection Options](https://developer.apple.com/documentation/corebluetooth/cbcentralmanager/peripheral_connection_options)
    /// - returns: `Observable<CMState>`
    ///
    public func connect(_ peripheral: CBPeripheral, options: [String: Any]? = nil) -> Observable<CMState> {
        defer { connector.connect(peripheral: peripheral, options: options) }
        return stateObservable.filter { $0.state == .connected }.take(1)
    }
    
    /// disconnect current peripheral
    ///
    /// - returns: `Observable<CMState>`
    public func disconnect() -> Observable<CMState> {
        defer { connector.disconnect() }
        return stateObservable
            .filter { $0.state == .disconnect }
            .take(1)
    }
    
    /// observe scanned peripheral
    ///
    /// **see also:** `startScan`, `stopScan`
    /// - returns: `Observable<CMState>`
    public func observeScanned() -> Observable<CMState> {
        return stateObservable.filter { $0.state == .scanned }
    }
    
    /// observe bytes stream
    public func observeNotificationBytes() -> Observable<UInt8> {
        return stateObservable.filter { $0.state == .notification }
            .map { $0.data!.toArray() }
            .flatMap { Observable.from($0) }
    }
    
    
    /// observe measure success
    /// - returns: `Observable<CMState>`
    ///
    ///  ```
    ///  // Please remember to destroy the subscription
    ///  cm.observeMeasure()
    ///     .concatMap { _ in
    ///         return cm.getMeasureData()
    ///     }
    ///     .subscribe(
    ///         onNext: { data in
    ///             // todo
    ///         }
    ///     )
    ///
    ///  ```
    ///
    public func observeMeasure() -> Observable<CMState> {
        return stateObservable
            .filter { [weak self] state in
                if !(self?.waitingMeasure ?? false) && state.state == .notification, let data = state.data {
                    return data.elementsEqual([0xbb, 0x01, 0x00, 0x00, 0x01, 0x90, 0x0a, 0x1f, 0xff, 0x75])
                }
                return false;
            }
    }
    
    /// exec command
    /// - parameter command: `CMCommand` command
    /// - returns: `Observable<Data?>`
    public func execCommand(command: Command) -> Observable<Data?> {
        return Observable<Data?>.create { [weak self] observer in
            var disposable: Disposable? = nil
            if let strongSelf = self {
                if !strongSelf.connector.isConnected {
                    observer.onError(CMError.peripheralDisconnect)
                } else {
                    strongSelf.connector.writeData(data: command.data)
                    if command.responseBytesCount == 0 {
                        observer.onNext(nil)
                        observer.onCompleted()
                    } else {
                        disposable = strongSelf.observeNotificationBytes()
                            .buffer(timeSpan: .seconds(command.timeout), count: command.responseBytesCount, scheduler: ConcurrentDispatchQueueScheduler(queue: .global()))
                            .subscribe(
                                onNext: { data in
                                    if data.count < command.responseBytesCount {
                                        observer.onError(CMError.responseTimeout)
                                    } else if data.count != command.responseBytesCount || !Command.validate(data: data) {
                                        observer.onError(CMError.invalidResponseData)
                                    } else {
                                        observer.onNext(data.data)
                                        observer.onCompleted()
                                    }
                                },
                                onError: { (err) in
                                    observer.onError(err)
                                }
                            )
                    }
                }
            }
            
            return Disposables.create {
                disposable?.dispose()
            }
        }
    }
    
    /// send wakeup peripheral
    public func wakeup () -> Observable<Void> {
        return execCommand(command: .wakeUp)
            .delay(.milliseconds(50), scheduler: MainScheduler.instance)
            .map { _ in () }
    }
    
    // MARK: - Measure
    
    /// measure
    public func measure(_ mode: MeasureData.MeasureMode = .SCI) -> Observable<Void> {
        self.waitingMeasure = true
        return wakeup()
            .concatMap { [weak self] _ -> Observable<Data?> in
                if let strongSelf = self {
                    return strongSelf.execCommand(command: .measure(mode))
                }
                return .of(nil)
            }
            .map { [weak self] _ in
                self?.waitingMeasure = false
            }
    }
    
    /// get measurement data
    public func getMeasureData(_ mode: MeasureData.MeasureMode = .SCI) -> Observable<MeasureData?> {
        return wakeup()
            .concatMap { [weak self] _ -> Observable<Data?> in
                if let strongSelf = self {
                    return strongSelf.execCommand(command: .getMeasureData(mode))
                }
                return Observable.of(nil)
            }.map { data in
                if let data = data {
                    return MeasureData(data: data, from: .measure)
                }
                return nil
            }
    }
    
    /// measure and get measurement data
    ///
    /// Is a combination of the `measure` and the `getMeasureData`
    ///
    /// - parameter mode: measure mode: `SCI`, `SCE` ....
    /// - returns: `Observable<MeasureData?>`
    ///
    /// ```
    /// let cm = CMKit()
    /// _ = cm.measureWithResponse().subscribe(onNext: { data in
    ///     if let data = data {
    ///         // todo ...
    ///     }
    /// })
    /// ```
    ///
    public func measureWithResponse(_ mode: MeasureData.MeasureMode = .SCI) -> Observable<MeasureData?> {
        return measure(mode)
            .concatMap { [weak self] _ -> Observable<MeasureData?> in
                if let strongSelf = self {
                    return strongSelf.getMeasureData(mode)
                }
                return .of(nil)
            }
    }
    
    // MARK: - Calibration
    
    /// black calibrate
    public func blackCalibrate() -> Observable<Void> {
        return wakeup()
            .concatMap { [weak self] _ -> Observable<Data?> in
                if let strongSelf = self {
                    return strongSelf.execCommand(command: .blackCalibrate)
                }
                return .of(nil)
            }
            .concatMap { (data: Data?) -> Observable<Bool> in
                if data != nil {
                    if let res = data?[2] {
                        if res == 0 {
                            return .of(true)
                        }
                    }
                }
                return .error(CMError.calibrateFailure);
            }
            .map { _ in () }
    }
    
    /// white calibrate
    public func whiteCalibrate() -> Observable<Void> {
        return wakeup()
            .concatMap { [weak self] _ -> Observable<Data?> in
                if let strongSelf = self {
                    return strongSelf.execCommand(command: .whiteCalibrate)
                }
                return .of(nil)
            }
            .concatMap { (data: Data?) -> Observable<Bool> in
                if data != nil {
                    if let res = data?[2] {
                        if res == 0 {
                            return .of(true)
                        }
                    }
                }
                return .error(CMError.calibrateFailure);
            }
            .map { _ in () }
    }
    
    
    // MARK: - Peripheral Storage
    
    /// The amount of data obtained from the device
    public func getStorageCount() -> Observable<Int> {
        return wakeup()
            .concatMap { [weak self] _ -> Observable<Data?> in
                if let strongSelf = self {
                    return strongSelf.execCommand(command: .getStorageCount)
                }
                return .of(nil)
            }
            .map { data in
                if let data = data {
                    return Int(data[3]) + Int(data[4]) << 8;
                }
                return -1
            }
    }
    
    /// get specified data from the peripheral
    public func getStorageData(_ index: UInt16) -> Observable<MeasureData?> {
        return wakeup()
            .concatMap { [weak self] _ -> Observable<Data?> in
                if let strongSelf = self {
                    return strongSelf.execCommand(command: .getStorageData(index))
                }
                return .of(nil)
            }
            .map { data in
                if let data = data {
                    return MeasureData(data: data, from: .storage)
                }
                return nil
            }
    }
    
    /// Clear all data on connected peripheral
    public func clearStorage() -> Observable<Void> {
        return wakeup()
            .concatMap { [weak self] _ -> Observable<Data?> in
                if let strongSelf = self {
                    return strongSelf.execCommand(command: .clearStorage)
                }
                return .of(nil)
            }
            .map { _ in () }
    }
    
    /// Delete the specified data on connected peripheral
    public func deleteStorage(_ index: UInt16) -> Observable<Void> {
        return wakeup()
            .concatMap { [weak self] _ -> Observable<Data?> in
                if let strongSelf = self {
                    return strongSelf.execCommand(command: .deleteStorage(index))
                }
                return .of(nil)
            }
            .map { _ in () }
    }
    
    /// Transfer a piece of data to connected peripheral
    public func transferData(_ data: MeasureData) -> Observable<Data?> {
        return wakeup()
            .concatMap { [weak self] _ -> Observable<Data?> in
                if let strongSelf = self {
                    return strongSelf.execCommand(command: .transferData(data))
                }
                
                return .of(nil)
            }
    }
    
    
    /// get connected peripheral last calibration date,
    /// determine whether to recalibrate
    public func getCalibrationState() -> Observable<CalibrationState?> {
        return wakeup()
            .concatMap { [weak self] _ -> Observable<Data?> in
                if let strongSelf = self {
                    return strongSelf.execCommand(command: .getCalibrationState)
                }
                return .of(nil)
            }
            .map { data in
                if let data = data {
                    return CalibrationState(data: data)
                }
                return nil
            }
    }
    
    
    // MARK: - Display Settings
    
    
    /// modify display settings
    ///
    /// - parameter parameter: `DisplayParameter`
    /// - returns: `Observable<Void>`
    ///
    /// ```
    /// let cm = CMKit()
    /// _ = cm.setDisplayParameter(.init(
    ///     firstLightSource: LightSource(angle: .deg10, category: .D65),
    ///     secondLightSource: LightSource(angle: .deg10, category: .D50),
    ///     measureMode: .SCI,
    ///     colorMode: .whiteness,
    ///     differenceFormula: .CIE_dE_ab
    /// ))
    /// .subscribe()
    /// ```
    public func setDisplayParameter(_ parameter: DisplayParameter) -> Observable<Void> {
        return wakeup()
            .concatMap { [weak self] _ -> Observable<Data?> in
                if let strongSelf = self {
                    return strongSelf.execCommand(command: .setDisplayParameter(parameter))
                }
                return .of(nil)
            }
            .map { _ in () }
    }
    
    /// set whiteness type
    ///
    /// If the color mode is set to whiteness, you can set the specific whiteness type by this method
    ///
    /// - parameter whiteness: `ColorMode.Whiteness` whiteness type
    /// - returns: `Observable<Void>`
    ///
    /// ```
    /// let cm = CMKit()
    /// _ = cm.setDisplayParameter(.init(
    ///     firstLightSource: LightSource(angle: .deg10, category: .D65),
    ///     secondLightSource: LightSource(angle: .deg10, category: .D50),
    ///     measureMode: .SCI,
    ///     colorMode: .whiteness,
    ///     differenceFormula: .CIE_dE_ab
    /// ))
    /// .concatMap { _ -> Observable<Void> in
    ///     return cm.setWhiteness(.ASTM)
    /// }
    /// .subscribe()
    /// ```
    ///
    public func setWhiteness(_ whiteness: ColorMode.Whiteness) -> Observable<Void> {
        return wakeup()
            .concatMap { [weak self] _ -> Observable<Data?> in
                if let strongSelf = self {
                    return strongSelf.execCommand(command: .setWhiteness(whiteness))
                }
                return .of(nil)
            }
            .map { _ in () }
    }
    
    
    // MARK: - Tolerance Settings
    
    /// modify tolerance settings
    public func setToleranceParameter(_ parameter: ToleranceParameter) -> Observable<Void> {
        return wakeup()
            .concatMap { [weak self] _ -> Observable<Data?> in
                if let strongSelf = self {
                    return strongSelf.execCommand(command: .setToleranceParameter(parameter))
                }
                return .of(nil)
            }
            .map { _ in () }
    }
}

