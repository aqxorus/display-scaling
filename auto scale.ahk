#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

OnMessage(0x007E, OnDisplayChange)

UpdateLaptopScale()

OnDisplayChange(wParam, lParam, msg, hwnd) {
    SetTimer(UpdateLaptopScale, -1500)
}

UpdateLaptopScale() {
    monCount := MonitorGetCount()
    if (monCount > 1) {
        SetInternalDisplayScale(150) ; external monitor connected -> 150%
    } else {
        SetInternalDisplayScale(125) ; only laptop screen -> 125%
    }
}

SetInternalDisplayScale(targetScale) {
    static scales := [100, 125, 150, 175, 200, 225, 250, 300, 350, 400, 450, 500]
    targetIdx := 0
    for idx, val in scales {
        if (val = targetScale) {
            targetIdx := idx
            break
        }
    }
    if (!targetIdx)
        return

    pathCount := 0, modeCount := 0
    if DllCall("GetDisplayConfigBufferSizes", "UInt", 2, "UInt*", &pathCount, "UInt*", &modeCount) != 0
        return

    paths := Buffer(72 * pathCount, 0)
    modes := Buffer(64 * modeCount, 0)
    if DllCall("QueryDisplayConfig", "UInt", 2, "UInt*", &pathCount, "Ptr", paths, "UInt*", &modeCount, "Ptr", modes, "Ptr", 0) != 0
        return

    targetPathOffset := -1

    Loop pathCount {
        offset := (A_Index - 1) * 72
        outputTech := NumGet(paths, offset + 36, "UInt")
        if (outputTech = 0x80000000 || outputTech = 11 || outputTech = 6) {
            targetPathOffset := offset
            break
        }
    }

    if (targetPathOffset = -1 && pathCount > 0)
        targetPathOffset := 0

    if (targetPathOffset = -1)
        return

    adapterId := NumGet(paths, targetPathOffset + 0, "Int64")
    sourceId  := NumGet(paths, targetPathOffset + 8, "UInt")

    getPacket := Buffer(32, 0)
    NumPut("Int", -3, "UInt", 32, "Int64", adapterId, "UInt", sourceId, getPacket, 0)
    if DllCall("DisplayConfigGetDeviceInfo", "Ptr", getPacket) != 0
        return

    minScaleRel := NumGet(getPacket, 20, "Int")
    curScaleRel := NumGet(getPacket, 24, "Int")
    maxScaleRel := NumGet(getPacket, 28, "Int")

    recIdx := 1 - minScaleRel
    desiredRel := targetIdx - recIdx

    if (desiredRel < minScaleRel)
        desiredRel := minScaleRel
    if (desiredRel > maxScaleRel)
        desiredRel := maxScaleRel
    if (desiredRel = curScaleRel)
        return

    setPacket := Buffer(24, 0)
    NumPut("Int", -4, "UInt", 24, "Int64", adapterId, "UInt", sourceId, "Int", desiredRel, setPacket, 0)
    DllCall("DisplayConfigSetDeviceInfo", "Ptr", setPacket)
}
