DefinitionBlock ("", "SSDT", 2, "TEST", "LOOP", 0x00000001)
{
    External (\_SB.PCI0.LPCB.ECDV.ECR1, MethodObj)

    Method (MAIN, 0, NotSerialized)
    {
        Local0 = 0x00
        While ((Local0 < 0x7530))
        {
            \_SB.PCI0.LPCB.ECDV.ECR1 (0x34)
            Local0++
        }
        Return (Local0)
    }
}
