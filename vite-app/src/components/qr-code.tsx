// Simple QR Code component using SVG
// For production, consider using react-qr-code library

interface QRCodeProps {
  value: string
  size?: number
  level?: 'L' | 'M' | 'Q' | 'H'
}

export function QRCode({ value }: QRCodeProps) {
  // Simple QR code placeholder - in production, use a proper QR code library
  // This is a visual placeholder that can be replaced with react-qr-code
  return (
    <div className="bg-white p-4 rounded-lg shadow-lg">
      <div className="w-full h-full flex items-center justify-center bg-white">
        <div className="text-center space-y-2">
          <div className="text-xs text-gray-500 mb-2">QR Code</div>
          <div className="border-2 border-dashed border-gray-300 rounded p-8">
            <div className="text-sm text-gray-400">
              {value.substring(0, 30)}...
            </div>
            <div className="text-xs text-gray-500 mt-2">
              Scan to download
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}


