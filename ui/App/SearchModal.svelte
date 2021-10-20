<!--
 Copyright © 2021 The Radicle Upstream Contributors

 This file is part of radicle-upstream, distributed under the GPLv3
 with Radicle Linking Exception. For full terms see the included
 LICENSE file.
-->
<script lang="ts">
  import type * as project from "ui/src/project";
  import type * as proxyProject from "proxy-client/project";

  import { fade } from "svelte/transition";

  import * as error from "ui/src/error";
  import * as modal from "ui/src/modal";
  import * as notification from "ui/src/notification";
  import * as proxy from "ui/src/proxy";
  import * as remote from "ui/src/remote";
  import * as router from "ui/src/router";
  import * as validation from "ui/src/validation";

  import {
    CopyableIdentifier,
    FollowToggle,
    Icon,
    TextInput,
  } from "ui/DesignSystem";

  import ProjectStats from "ui/App/SharedComponents/ProjectStats.svelte";

  export let inputValue: string = "";

  const VALID_URN_MATCH = /^rad:git:[1-9A-HJ-NP-Za-km-z]{37}/;
  const urnConstraints = {
    format: {
      pattern: VALID_URN_MATCH,
      message: `Not a valid Radicle ID`,
    },
  };

  const projectRequestStore = remote.createStore<proxyProject.Request>();
  const projectSearchStore = remote.createStore<proxyProject.Project>();
  const urnValidation = validation.createValidationStore(urnConstraints);

  function navigateToProject(project: project.Project) {
    reset();
    router.push({
      type: "project",
      params: {
        urn: project.urn,
        activeView: { type: "files" },
      },
    });
    modal.hide();
  }

  function onKeydown(event: KeyboardEvent) {
    switch (event.code) {
      case "Enter":
        if ($projectSearchStore.status === remote.Status.Success) {
          navigateToProject($projectSearchStore.data);
        } else if ($projectSearchStore.status === remote.Status.Error) {
          follow();
        }
        break;
      case "Escape":
        reset();
        modal.hide();
        break;
    }
  }

  function reset(): void {
    projectRequestStore.reset();
    projectSearchStore.reset();
  }

  async function requestProject(urn: string): Promise<void> {
    projectRequestStore.loading();
    try {
      const projectRequest = await proxy.client.project.requestSubmit(urn);
      projectRequestStore.success(projectRequest);
    } catch (err: unknown) {
      projectRequestStore.error(error.fromUnknown(err));
    }
  }

  async function searchProject(urn: string): Promise<void> {
    projectSearchStore.loading();
    try {
      const project = await proxy.client.project.get(urn);
      projectSearchStore.success(project);
    } catch (err: unknown) {
      projectSearchStore.error(error.fromUnknown(err));
    }
  }

  function follow() {
    if ($urnValidation.status === validation.ValidationStatus.Success) {
      requestProject(sanitizedInputValue);
    }
  }

  $: sanitizedInputValue = inputValue.trim();

  // Validate input entered, at the moment valid RadUrns are the only
  // acceptable input.
  $: if (sanitizedInputValue && sanitizedInputValue.length > 0) {
    urnValidation.validate(sanitizedInputValue);
  } else {
    urnValidation.reset();
  }

  // To support quick pasting, request the urn once valid to get tracking
  // information.
  $: if ($urnValidation.status === validation.ValidationStatus.Success) {
    searchProject(sanitizedInputValue);
  }

  // Reset searches if the input became invalid.
  $: if ($urnValidation.status !== validation.ValidationStatus.Success) {
    reset();
  }

  // Fire notification when a request has been created.
  $: if ($projectRequestStore.status === remote.Status.Success) {
    reset();
    router.push({ type: "profile", activeTab: "following" });
    notification.info({
      message: "You’ll be notified when this project has been found.",
    });
    modal.hide();
  }

  $: if ($projectRequestStore.status === remote.Status.Error) {
    error.show($projectRequestStore.error);
  }
</script>

<style>
  .container {
    width: 30rem;
  }

  .search-bar {
    align-items: center;
    background-color: var(--color-foreground-level-1);
    border-radius: 0.5rem;
    border: 0;
    box-shadow: var(--color-shadows);
    color: var(--color-foreground-level-6);
    display: flex;
    height: 3rem;
    margin-bottom: 1rem;
    position: relative;
  }

  .result {
    background: var(--color-background);
    border-radius: 0.5rem;
    box-shadow: var(--color-shadows);
    position: absolute;
    width: 30rem;
    color: var(--color-foreground-level-6);
  }

  .header {
    align-items: center;
    cursor: pointer;
    display: flex;
    justify-content: space-between;
    margin-bottom: 1rem;
  }

  .project-name {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
</style>

<div class="container" data-cy="search-modal">
  <div class="search-bar">
    <Icon.MagnifyingGlass style="margin-left: 0.5rem;" />
    <TextInput
      dataCy="search-input"
      style="flex: 1;"
      inputStyle="border: 0;"
      autofocus
      bind:value={inputValue}
      on:keydown={onKeydown}
      placeholder="Enter a project’s Radicle ID here…"
      hint={$urnValidation.status === validation.ValidationStatus.Success
        ? "↵"
        : ""} />
  </div>

  {#if $projectSearchStore.status === remote.Status.Success}
    <div class="result" out:fade|local={{ duration: 100 }}>
      <div style="padding: 1.5rem;">
        <h3
          class="header"
          data-cy="project-name"
          on:click={navigateToProject.bind(null, $projectSearchStore.data)}>
          <span class="project-name"
            >{$projectSearchStore.data.metadata.name}</span>
          <FollowToggle disabled following={true} />
        </h3>

        <p style="margin-bottom: 1rem;">
          {$projectSearchStore.data.metadata.description}
        </p>

        <ProjectStats
          branches={$projectSearchStore.data.stats.branches}
          commits={$projectSearchStore.data.stats.commits}
          contributors={$projectSearchStore.data.stats.contributors} />
      </div>
    </div>
  {:else if $projectSearchStore.status === remote.Status.Error}
    <div class="result" out:fade|local={{ duration: 100 }}>
      <div style="padding: 1.5rem;">
        <h3 class="header">
          <CopyableIdentifier
            value={sanitizedInputValue}
            kind="radicleId"
            showIcon={false} />
          <FollowToggle on:follow={follow} style="margin-left: 1rem;" />
        </h3>

        <p>
          You’re not following this project yet, so there’s nothing to show
          here. Follow it and you’ll be notified as soon as it’s available.
        </p>
      </div>
    </div>
  {:else if $urnValidation.status === validation.ValidationStatus.Error}
    <div class="result" out:fade|local={{ duration: 100 }}>
      <div style="padding: 1.5rem;">
        <p>That's not a valid Radicle ID.</p>
      </div>
    </div>
  {/if}
</div>
