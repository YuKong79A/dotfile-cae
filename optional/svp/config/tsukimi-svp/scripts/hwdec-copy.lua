-- Tsukimi's hardware-decoding menu does not expose copy-back modes.
-- SVP's VapourSynth filter needs frames accessible in system memory.
mp.add_hook("on_load", 50, function()
    mp.set_property("hwdec", "nvdec-copy")
end)
