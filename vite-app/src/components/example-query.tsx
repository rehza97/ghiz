import { useQuery } from "@tanstack/react-query"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"

// Example API function
async function fetchUserData() {
  // Simulate API call
  await new Promise((resolve) => setTimeout(resolve, 1000))
  return {
    id: 1,
    name: "John Doe",
    email: "john@example.com",
    role: "Developer",
  }
}

export function ExampleQuery() {
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ["user"],
    queryFn: fetchUserData,
  })

  if (isLoading) {
    return (
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>React Query Example</CardTitle>
          <CardDescription>Loading user data...</CardDescription>
        </CardHeader>
      </Card>
    )
  }

  if (error) {
    return (
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>React Query Example</CardTitle>
          <CardDescription>Error loading data</CardDescription>
        </CardHeader>
        <CardContent>
          <Button onClick={() => refetch()}>Retry</Button>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card className="w-full max-w-md">
      <CardHeader>
        <CardTitle>React Query Example</CardTitle>
        <CardDescription>
          Data fetched using TanStack Query
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-2">
        {data && (
          <>
            <p><strong>ID:</strong> {data.id}</p>
            <p><strong>Name:</strong> {data.name}</p>
            <p><strong>Email:</strong> {data.email}</p>
            <p><strong>Role:</strong> {data.role}</p>
          </>
        )}
        <Button onClick={() => refetch()} className="mt-4">
          Refetch Data
        </Button>
      </CardContent>
    </Card>
  )
}


