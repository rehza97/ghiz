/**
 * Fill Test Data Button
 * Fills the current form with sample data from form-autofill.json for easy testing
 */

import { Button } from '@/components/ui/button'
import { TestTube2 } from 'lucide-react'
import { getFormTestDataForKey, type FormKey } from '@/utils/form-autofill'

interface FillTestDataButtonProps {
  formKey: FormKey
  onFill: (data: Record<string, unknown>) => void
  label?: string
  variant?: 'outline' | 'ghost' | 'link'
  size?: 'default' | 'sm' | 'lg'
  className?: string
}

export function FillTestDataButton({
  formKey,
  onFill,
  label = 'ملء بيانات تجريبية',
  variant = 'outline',
  size = 'sm',
  className = '',
}: FillTestDataButtonProps) {
  const handleClick = () => {
    const data = getFormTestDataForKey(formKey)
    onFill(data)
  }

  return (
    <Button
      type="button"
      variant={variant}
      size={size}
      onClick={handleClick}
      className={`text-amber-600 border-amber-300 hover:bg-amber-50 hover:text-amber-700 ${className}`}
      title="Fill form with test data for easy testing"
    >
      <TestTube2 className="h-4 w-4 ml-2" />
      {label}
    </Button>
  )
}
