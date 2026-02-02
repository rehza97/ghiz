/**
 * Form auto-fill utility for testing
 * Loads sample data from form-autofill.json - each call picks a random variation for variety
 */

import formAutofillData from '../../form-autofill.json'

export type FormKey = 'login' | 'library' | 'book' | 'floor' | 'shelf' | 'user' | 'example' | 'analytics'

interface FormInput {
  id: string
  name?: string
  type?: string
  value: string | number
  required?: boolean
  options?: string[]
}

interface FormConfig {
  inputs: Record<string, FormInput>
  variations?: Record<string, unknown>[]
}

const forms = formAutofillData.forms as Record<FormKey, FormConfig>

function inputsToData(config: FormConfig): Record<string, unknown> {
  const data: Record<string, unknown> = {}
  for (const [key, input] of Object.entries(config.inputs || {})) {
    const inp = input as FormInput
    const fieldName = inp.name ?? key
    let val = inp.value
    if (inp.type === 'number' && typeof val === 'string') {
      val = Number(val) || 0
    }
    if (val !== '' && val != null) {
      data[fieldName] = val
    }
  }
  return data
}

/** Get test data as plain object { fieldName: value } for a form */
export function getFormTestData(formKey: FormKey): Record<string, string | number | undefined> {
  const data = getFormTestDataForKey(formKey)
  return data as Record<string, string | number | undefined>
}

/**
 * Get test data - picks a random variation when available for variety.
 * Each Fill click returns different sample data.
 */
export function getFormTestDataForKey(formKey: FormKey): Record<string, unknown> {
  const config = forms[formKey]
  if (!config) return {}

  const variations = config.variations
  if (variations && variations.length > 0) {
    const idx = Math.floor(Math.random() * variations.length)
    return { ...variations[idx] }
  }

  return inputsToData(config)
}

/** Export raw forms config for advanced usage */
export { forms }
