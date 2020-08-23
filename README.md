[![Test](https://github.com/hraban/opus/workflows/Test/badge.svg)](https://github.com/hraban/opus/actions?query=workflow%3ATest)

## Go wrapper for Opus

This package provides Go bindings for the xiph.org C libraries libopus.

The C libraries and docs are hosted at https://opus-codec.org/. This package
just handles the wrapping in Go, and is unaffiliated with xiph.org.

This is a fork of the original project at https://github.com/hraban/opus that
has been modified to be friendlier towards fully static builds

## Details

This wrapper provides a Go translation layer for two elements from the
xiph.org opus libs:

* encoders
* decoders

Perhaps I will add in libopusfile support later, but I'm not going
to be using it any time soon

### Import

```go
go get -u github.com/dbl0null/opus static-build
import "github.com/dbl0null/opus"
```

### Encoding

To encode raw audio to the Opus format, create an encoder first:

```go
const sampleRate = 48000
const channels = 1 // mono; 2 for stereo

enc, err := opus.NewEncoder(sampleRate, channels, opus.AppVoIP)
if err != nil {
    ...
}
```

Then pass it some raw PCM data to encode.

Make sure that the raw PCM data you want to encode has a legal Opus frame size.
This means it must be exactly 2.5, 5, 10, 20, 40 or 60 ms long. The number of
bytes this corresponds to depends on the sample rate (see the [libopus
documentation](https://www.opus-codec.org/docs/opus_api-1.1.3/group__opus__encoder.html)).

```go
var pcm []int16 = ... // obtain your raw PCM data somewhere
const bufferSize = 1000 // choose any buffer size you like. 1k is plenty.

// Check the frame size. You don't need to do this if you trust your input.
frameSize := len(pcm) // must be interleaved if stereo
frameSizeMs := float32(frameSize) / channels * 1000 / sampleRate
switch frameSizeMs {
case 2.5, 5, 10, 20, 40, 60:
    // Good.
default:
    return fmt.Errorf("Illegal frame size: %d bytes (%f ms)", frameSize, frameSizeMs)
}

data := make([]byte, bufferSize)
n, err := enc.Encode(pcm, data)
if err != nil {
    ...
}
data = data[:n] // only the first N bytes are opus data. Just like io.Reader.
```

Note that you must choose a target buffer size, and this buffer size will affect
the encoding process:

> Size of the allocated memory for the output payload. This may be used to
> impose an upper limit on the instant bitrate, but should not be used as the
> only bitrate control. Use `OPUS_SET_BITRATE` to control the bitrate.

-- https://opus-codec.org/docs/opus_api-1.1.3/group__opus__encoder.html

### Decoding

To decode opus data to raw PCM format, first create a decoder:

```go
dec, err := opus.NewDecoder(sampleRate, channels)
if err != nil {
    ...
}
```

Now pass it the opus bytes, and a buffer to store the PCM sound in:

```go
var frameSizeMs float32 = ...  // if you don't know, go with 60 ms.
frameSize := channels * frameSizeMs * sampleRate / 1000
pcm := make([]byte, int(frameSize))
n, err := dec.Decode(data, pcm)
if err != nil {
    ...
}

// To get all samples (interleaved if multiple channels):
pcm = pcm[:n*channels] // only necessary if you didn't know the right frame size

// or access sample per sample, directly:
for i := 0; i < n; i++ {
    ch1 := pcm[i*channels+0]
    // For stereo output: copy ch1 into ch2 in mono mode, or deinterleave stereo
    ch2 := pcm[(i*channels)+(channels-1)]
}
```

Note regarding Forward Error Correction (FEC):
> When a packet is considered "lost", `DecodeFEC` and `DecodeFECFloat32` methods
> can be called on the next packet in order to try and recover some of the lost
> data. The PCM needs to be exactly the duration of audio that is missing.
> `LastPacketDuration()` can be used on the decoder to get the length of the
> last packet.
> Note also that in order to use this feature the encoder needs to be configured
> with `SetInBandFEC(true)` and `SetPacketLossPerc(x)` options.

See https://godoc.org/gopkg.in/hraban/opus.v2#Stream for further info.

### API Docs

Go wrapper API reference (for the original package):
https://godoc.org/gopkg.in/hraban/opus.v2

Full libopus C API reference:
https://www.opus-codec.org/docs/opus_api-1.1.3/

For more examples, see the `_test.go` files.

## Build & Installation

Due to the limitations of the go build system, there is no way to
automatically build the opus libraries needed. You have few choices:


* ensure Go Module support is enabled (it likely is on any recent go package)  
  Then run:

```sh
  $ go mod -vendor
  $ bash ./vendor/github.com/dbl0null/opus/make-opus.sh
  $ go build -mod=vendor
```

  On most systems, this will result in a nearly fully static compile, some
  other (common) system libraries may be linked in.

* Even better, fully static linkage.  
  Install musl, either from your package management system, or from
  [their website](https://www.musl-libc.org/how.html). This will give
  you a wrapper around gcc that will build against musl.

```sh
  $ env CC=musl-gcc bash ./vendor/github.com/dbl0null/opus/make-opus.sh
  $ env CC=musl-gcc go build -mod=vendor -ldflags='-linkmode=external "-extldflags=-static -s"'
  $ file mumbledj
  mumbledj: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked,Go BuildID=xaxkEkC5v0ll3GI5NfvP/xE8TI5-2z621pbKmWAXz/pQESQrCQPQKB6qnYSgYh/IaLyIdrPghEgcyCsI8tm, stripped
```

* (Not the recommended choice)  
  install the opus and (if needed) the development opus packages from your
  package manager.

  Then you need to invoke your build for your project so that it knows
  where to find everything:  

```
  $ env CGO_CPPFLAGS="$(pkg-config --cflags opus)"  CGO_LDFLAGS="$(pkg-config --libs opus)" go build
```

  If your package manager doesn't install static libraries (which is the usual case) you will
  have to have libopus installed on whatever system that you plan to run the compiled application on

### Linking libopus and libopusfile

Just don't. Use [the original package](https://godoc.org/gopkg.in/hraban/opus.v2) if you don't
want static compilation.

## License

The licensing terms for the Go bindings are found in the LICENSE file. The
authors and copyright holders are listed in the AUTHORS file.

The copyright notice uses range notation to indicate all years in between are
subject to copyright, as well. This statement is necessary, apparently. For all
those nefarious actors ready to abuse a copyright notice with incorrect
notation, but thwarted by a mention in the README. Pfew!
