<!--
 Copyright © 2021 The Radicle Upstream Contributors

 This file is part of radicle-upstream, distributed under the GPLv3
 with Radicle Linking Exception. For full terms see the included
 LICENSE file.
-->
<script lang="ts">
  import type { ValidationState } from "ui/src/validation";

  import { ValidationStatus as Status } from "ui/src/validation";

  import Icon from "./Icon";
  import KeyHint from "./KeyHint.svelte";
  import Spinner from "./Spinner.svelte";

  export let autofocus: boolean = false;
  export let disabled: boolean = false;
  export let showSuccessCheck: boolean = false;
  export let concealed: boolean = false;

  export let dataCy: string | undefined = undefined;
  export let hint: string | undefined = undefined;
  export let inputStyle: string | undefined = undefined;
  export let placeholder: string | undefined = undefined;
  export let style: string | undefined = undefined;
  export let suffix: string | undefined = undefined;
  export let validation: ValidationState | undefined = undefined;
  export let value: string | undefined = undefined;

  export const focus = (): void => {
    inputElement && inputElement.focus();
  };

  let inputElement: HTMLInputElement | undefined = undefined;

  // Can't use normal `autofocus` attribute on the `inputElement`: "Autofocus
  // processing was blocked because a document's URL has a fragment".
  // preventScroll is necessary for onboarding animations to work.
  $: if (autofocus) {
    inputElement && inputElement.focus({ preventScroll: true });
  }

  // We do it this way to work around the svelte-check error: 'type' attribute
  // cannot be dynamic if input uses two-way binding (svelte).
  $: if (inputElement) {
    inputElement.type = concealed ? "password" : "text";
  }
</script>

<style>
  .wrapper {
    display: flex;
    flex-direction: column;
    position: relative;
  }

  input {
    border: 1px solid var(--color-foreground-level-3);
    padding: 0.5rem;
    border-radius: 0.5rem;
    width: 100%;
    height: 2.5rem;
    line-height: 3rem;
    padding: 0 0.75rem;
    background-color: var(--color-background);
  }

  input[disabled] {
    cursor: not-allowed;
    color: var(--color-foreground-level-4);
    background-color: var(--color-foreground-level-1);
  }

  input[disabled]::placeholder {
    color: var(--color-foreground-level-4);
  }

  input[disabled]:hover {
    background-color: var(--color-foreground-level-1);
  }

  .concealed {
    color: var(--color-foreground-level-6);
  }

  input::placeholder {
    color: var(--color-foreground-level-5);
  }

  .suffix {
    color: var(--color-foreground-level-5);
  }

  input:focus,
  input:hover {
    outline: none;
    border: 1px solid
      var(--focus-outline-color, var(--color-foreground-level-3));
    background-color: var(--color-foreground-level-1);
  }

  input.invalid:focus,
  input.invalid {
    outline: none;
    border: 1px solid var(--color-negative);
    background: var(--color-background);
    background-position: right 0.875rem top 55%;
  }

  input.padding {
    padding-right: 2.375rem;
  }

  input.invalid:focus {
    background: var(--color-foreground-level-1);
  }

  .validation-row {
    display: flex;
    align-items: center;

    margin: 0.75rem 0 0 0.75rem;
  }

  .validation-row p {
    color: var(--color-negative);
    text-align: left;
  }

  .hint {
    justify-content: flex-start;
    position: absolute;
    right: 0.75rem;
  }
</style>

<div {style} class="wrapper">
  <div on:click>
    <input
      style={inputStyle}
      class:invalid={validation && validation.status === Status.Error}
      class:padding={validation && validation.status !== Status.NotStarted}
      class:concealed
      data-cy={dataCy}
      {placeholder}
      {disabled}
      spellcheck={false}
      bind:value
      bind:this={inputElement}
      on:change
      on:input
      on:keydown
      on:keypress />
  </div>

  {#if hint && (validation === undefined || (validation && validation.status === Status.Success))}
    <div class="hint" style={`top: 6px`}>
      <KeyHint>{hint}</KeyHint>
    </div>
  {/if}

  {#if suffix}
    <p
      style="position: absolute; top: 8px; right: {validation &&
      validation.status !== Status.NotStarted
        ? '38px'
        : '10px'};"
      class="suffix">
      {suffix}
    </p>
  {/if}

  {#if validation}
    {#if validation && validation.status === Status.Loading}
      <Spinner
        style="justify-content: flex-start; position: absolute; height: 100%;
        right: 10px;" />
    {:else if validation && validation.status === Status.Success && showSuccessCheck}
      <Icon.CheckCircle
        style="fill: var(--color-positive); justify-content: flex-start;
        position: absolute; top: 8px; right: 10px;" />
    {:else if validation && validation.status === Status.Error}
      <Icon.ExclamationCircle
        dataCy="validation-error-icon"
        style="fill: var(--color-negative); justify-content: flex-start;
        position: absolute; top: 8px; right: 10px;" />
      <div class="validation-row">
        <p>{validation.message}</p>
      </div>
    {/if}
  {/if}
</div>
