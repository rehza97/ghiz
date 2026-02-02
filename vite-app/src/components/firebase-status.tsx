import { useEffect, useState } from 'react'
import { database, auth, firestore } from '@/lib/firebase'
import { ref, onValue, off } from 'firebase/database'
import { onAuthStateChanged } from 'firebase/auth'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { CheckCircle2, XCircle, Loader2, Wifi, WifiOff } from 'lucide-react'

type ConnectionStatus = 'connected' | 'disconnected' | 'checking' | 'error'

interface FirebaseStatus {
  database: ConnectionStatus
  auth: ConnectionStatus
  firestore: ConnectionStatus
}

export function FirebaseStatus() {
  const [status, setStatus] = useState<FirebaseStatus>({
    database: 'checking',
    auth: 'checking',
    firestore: 'checking',
  })
  const [lastChecked, setLastChecked] = useState<Date>(new Date())

  const checkDatabaseConnection = () => {
    if (!database) {
      setStatus(prev => ({ ...prev, database: 'error' }))
      return
    }

    try {
      const testRef = ref(database, '.info/connected')
      setStatus(prev => ({ ...prev, database: 'checking' }))

      const unsubscribe = onValue(testRef, (snapshot) => {
        if (snapshot.val() === true) {
          setStatus(prev => ({ ...prev, database: 'connected' }))
        } else {
          setStatus(prev => ({ ...prev, database: 'disconnected' }))
        }
        off(testRef)
      }, (error) => {
        console.error('Database connection error:', error)
        setStatus(prev => ({ ...prev, database: 'error' }))
        off(testRef)
      })

      // Timeout after 5 seconds – clean up listener and update status
      setTimeout(() => {
        unsubscribe()
        off(testRef)
        setStatus(prev => {
          if (prev.database === 'checking') {
            return { ...prev, database: 'error' }
          }
          return prev
        })
      }, 5000)
    } catch (error) {
      console.error('Database check error:', error)
      setStatus(prev => ({ ...prev, database: 'error' }))
    }
  }

  const checkAuthConnection = () => {
    if (!auth) {
      setStatus(prev => ({ ...prev, auth: 'error' }))
      return
    }

    try {
      setStatus(prev => ({ ...prev, auth: 'checking' }))
      
      const unsubscribe = onAuthStateChanged(
        auth,
        () => {
          setStatus(prev => ({ ...prev, auth: 'connected' }))
          setTimeout(() => unsubscribe(), 0)
        },
        (error) => {
          console.error('Auth connection error:', error)
          setStatus(prev => ({ ...prev, auth: 'error' }))
          setTimeout(() => unsubscribe(), 0)
        }
      )

      // Timeout after 5 seconds
      setTimeout(() => {
        unsubscribe()
        setStatus(prev => {
          if (prev.auth === 'checking') {
            return { ...prev, auth: 'error' }
          }
          return prev
        })
      }, 5000)
    } catch (error) {
      console.error('Auth check error:', error)
      setStatus(prev => ({ ...prev, auth: 'error' }))
    }
  }

  const checkFirestoreConnection = () => {
    if (!firestore) {
      setStatus(prev => ({ ...prev, firestore: 'error' }))
      return
    }

    try {
      setStatus(prev => ({ ...prev, firestore: 'checking' }))
      // Firestore connection is checked by verifying it's initialized
      // In a production app, you might want to do an actual read operation
      // For now, we'll check if firestore is properly initialized
      const isInitialized = firestore && typeof firestore === 'object'
      setStatus(prev => ({ 
        ...prev, 
        firestore: isInitialized ? 'connected' : 'disconnected' 
      }))
    } catch (error) {
      console.error('Firestore check error:', error)
      setStatus(prev => ({ ...prev, firestore: 'error' }))
    }
  }

  const checkAllConnections = () => {
    setLastChecked(new Date())
    checkDatabaseConnection()
    checkAuthConnection()
    checkFirestoreConnection()
  }

  useEffect(() => {
    checkAllConnections()

    // Check connection status every 30 seconds
    const interval = setInterval(checkAllConnections, 30000)

    return () => {
      clearInterval(interval)
    }
  }, [])

  const getStatusIcon = (connectionStatus: ConnectionStatus) => {
    switch (connectionStatus) {
      case 'connected':
        return <CheckCircle2 className="h-5 w-5 text-green-500" />
      case 'disconnected':
        return <WifiOff className="h-5 w-5 text-yellow-500" />
      case 'checking':
        return <Loader2 className="h-5 w-5 text-blue-500 animate-spin" />
      case 'error':
        return <XCircle className="h-5 w-5 text-red-500" />
    }
  }

  const getStatusText = (connectionStatus: ConnectionStatus) => {
    switch (connectionStatus) {
      case 'connected':
        return 'Connected'
      case 'disconnected':
        return 'Disconnected'
      case 'checking':
        return 'Checking...'
      case 'error':
        return 'Error'
    }
  }

  const getStatusColor = (connectionStatus: ConnectionStatus) => {
    switch (connectionStatus) {
      case 'connected':
        return 'text-green-500'
      case 'disconnected':
        return 'text-yellow-500'
      case 'checking':
        return 'text-blue-500'
      case 'error':
        return 'text-red-500'
    }
  }

  const allConnected = 
    status.database === 'connected' && 
    status.auth === 'connected' && 
    status.firestore === 'connected'

  return (
    <Card className="w-full">
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="flex items-center gap-2">
              <Wifi className="h-5 w-5" />
              Firebase Connection Status
            </CardTitle>
            <CardDescription>
              Last checked: {lastChecked.toLocaleTimeString()}
            </CardDescription>
          </div>
          <Button onClick={checkAllConnections} size="sm" variant="outline">
            Refresh
          </Button>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Overall Status */}
        <div className="flex items-center gap-2 p-3 rounded-lg bg-muted">
          {allConnected ? (
            <CheckCircle2 className="h-5 w-5 text-green-500" />
          ) : (
            <Loader2 className="h-5 w-5 text-blue-500 animate-spin" />
          )}
          <span className="font-medium">
            {allConnected ? 'All services connected' : 'Checking connections...'}
          </span>
        </div>

        {/* Individual Service Status */}
        <div className="space-y-3">
          <div className="flex items-center justify-between p-3 rounded-lg border">
            <div className="flex items-center gap-3">
              {getStatusIcon(status.database)}
              <div>
                <p className="font-medium">Realtime Database</p>
                <p className="text-sm text-muted-foreground">
                  {database ? 'Initialized' : 'Not initialized'}
                </p>
              </div>
            </div>
            <span className={getStatusColor(status.database)}>
              {getStatusText(status.database)}
            </span>
          </div>

          <div className="flex items-center justify-between p-3 rounded-lg border">
            <div className="flex items-center gap-3">
              {getStatusIcon(status.auth)}
              <div>
                <p className="font-medium">Authentication</p>
                <p className="text-sm text-muted-foreground">
                  {auth ? 'Initialized' : 'Not initialized'}
                </p>
              </div>
            </div>
            <span className={getStatusColor(status.auth)}>
              {getStatusText(status.auth)}
            </span>
          </div>

          <div className="flex items-center justify-between p-3 rounded-lg border">
            <div className="flex items-center gap-3">
              {getStatusIcon(status.firestore)}
              <div>
                <p className="font-medium">Firestore</p>
                <p className="text-sm text-muted-foreground">
                  {firestore ? 'Initialized' : 'Not initialized'}
                </p>
              </div>
            </div>
            <span className={getStatusColor(status.firestore)}>
              {getStatusText(status.firestore)}
            </span>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

