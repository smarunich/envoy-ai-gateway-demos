# Maintenance Guide

This document provides guidance for maintaining and extending the Envoy AI Gateway Demos project.

## Project Architecture

### Task-Based Orchestration

The project uses [Task](https://taskfile.dev/) as the primary orchestration tool, replacing traditional shell scripts with a declarative approach.

**Key Design Principles:**
- **Single Source of Truth**: `Taskfile.yml` contains all orchestration logic
- **Modular Scripts**: Each shell script handles one specific operation
- **Native Status Tracking**: Uses Task's built-in `generates` and `status` features
- **Dependency Management**: Tasks declare dependencies explicitly

### Status Tracking System

The project uses Task's native status tracking instead of custom solutions:

```yaml
task-name:
  cmds:
    - ./scripts/task-script.sh
    - touch .task/task-name.done
  generates:
    - .task/task-name.done
  status:
    - test -f .task/task-name.done
    - kubectl get deployment example  # Additional system checks
```

**Benefits:**
- Automatic up-to-date detection
- Idempotent operations
- Simple `task --status <task-name>` checking
- No custom JSON state files needed

## Task Organization

Tasks are organized in logical execution order in `Taskfile.yml`:

1. **Main Setup Tasks** (execution order):
   - `setup-all` - Complete orchestration
   - `install-deps` - Dependencies (kind, helm, kubectl)
   - `create-cluster` - Kind cluster creation
   - `install-envoy-gateway` - Envoy Gateway installation
   - `install-envoy-ai-gateway` - AI Gateway installation


2. **Status & Verification**:
   - `status` - Overall status display

3. **Utility Tasks**:
   - `cleanup` - Cluster and resource cleanup

4. **Monitoring & Debugging**:
   - `logs-envoy-gateway` - Gateway logs
   - `logs-ai-gateway` - AI Gateway logs
   - `port-forward` - Local access setup

## CI/CD Validation

### GitHub Actions Workflows

The project includes comprehensive CI/CD validation:

#### 1. Taskfile Validation (`.github/workflows/taskfile-validation.yml`)
- **Purpose**: Quick syntax and dependency validation
- **Triggers**: Push, PR, manual
- **Duration**: ~5 minutes
- **Checks**:
  - Taskfile syntax validation
  - Task dependency resolution
  - Shell script existence
  - Task status functionality

#### 2. Integration Test (`.github/workflows/integration-test.yml`)
- **Purpose**: Full end-to-end testing
- **Triggers**: Push to main, PR, daily schedule, manual
- **Duration**: ~30-45 minutes
- **Features**:
  - Complete `setup-all` execution
  - Idempotency testing (re-run validation)
  - Cleanup and re-setup cycle testing
  - Comprehensive failure logging
  - Artifact collection on failure

#### 3. Validate Setup (`.github/workflows/validate-setup.yml`)
- **Purpose**: Component validation and connectivity
- **Triggers**: Push, PR, manual
- **Duration**: ~20-30 minutes
- **Checks**:
  - All components running correctly
  - Service connectivity
  - Gateway functionality

#### 4. Status Badge (`.github/workflows/status-badge.yml`)
- **Purpose**: Lightweight validation for badges
- **Triggers**: Push to main, every 6 hours, manual
- **Duration**: ~5 minutes
- **Checks**: Basic validation and script existence

## Maintenance Tasks

### Adding New Components

1. **Create Shell Script**:
   ```bash
   # Create new script in scripts/
   touch scripts/install-new-component.sh
   chmod +x scripts/install-new-component.sh
   ```

2. **Add Task to Taskfile.yml**:
   ```yaml
   install-new-component:
     desc: Install new component
     deps: [prerequisite-task]
     cmds:
       - ./scripts/install-new-component.sh {{.KUBECONFIG}}
       - touch .task/install-new-component.done
     generates:
       - .task/install-new-component.done
     status:
       - test -f .task/install-new-component.done
       - kubectl get deployment new-component -n namespace
   ```

3. **Update Dependencies**:
   - Add to appropriate task's `deps` array
   - Update `setup-all` dependency chain if needed

4. **Update CI/CD**:
   - Add to workflow validation lists
   - Update integration test checks

### Updating Versions

Version updates are centralized in `Taskfile.yml` variables:

```yaml
vars:
  CLUSTER_NAME: envoy-ai-gateway-demo
  KIND_VERSION: v0.29.0
  ENVOY_GATEWAY_VERSION: v0.0.0-latest
  ENVOY_AI_GATEWAY_VERSION: v0.0.0-latest
```

**Update Process:**
1. Modify version in `vars` section
2. Test locally: `task cleanup && task setup-all`
3. Verify CI/CD passes
4. Update README.md if needed

### Debugging Failed Tasks

1. **Check Task Status**:
   ```bash
   task --status <task-name>
   task --dry <task-name>  # See what would run
   ```

2. **Check Status Files**:
   ```bash
   ls -la .task/
   cat .task/<task-name>.done
   ```

3. **Run Individual Components**:
   ```bash
   task install-deps
   task create-cluster
   # etc.
   ```

4. **Check Logs**:
   ```bash
   task logs-envoy-gateway
   task logs-ai-gateway
   ```

5. **Manual Verification**:
   ```bash
   kubectl get pods --all-namespaces --kubeconfig=kubeconfig.yaml
   kubectl get services --all-namespaces --kubeconfig=kubeconfig.yaml
   ```

### Troubleshooting CI/CD

**Common Issues:**

1. **Resource Constraints**: GitHub Actions runners have limited resources
   - Solution: Added disk cleanup steps
   - Monitor: Check workflow logs for resource usage

2. **Timing Issues**: Components may need more time to start
   - Solution: Added appropriate `kubectl wait` commands
   - Adjust: Increase timeouts if needed

3. **Network Issues**: Docker/Kubernetes networking
   - Solution: Use Docker Buildx setup
   - Debug: Check docker and kind logs

**Debugging Failed Workflows:**

1. Check workflow logs in GitHub Actions tab
2. Download failure artifacts (logs, kind exports)
3. Run locally: `act` tool can simulate GitHub Actions
4. Test specific workflow steps locally

### Performance Optimization

**Task Execution:**
- Tasks use `generates` and `status` for skip logic
- Parallel execution where possible (Task handles this)
- Minimal Docker layer rebuilds

**CI/CD Optimization:**
- Matrix strategies for version testing
- Artifact caching where appropriate
- Resource cleanup to prevent disk space issues

## Best Practices

### Task Development
1. **Single Responsibility**: Each task does one thing well
2. **Idempotent**: Tasks can be run multiple times safely
3. **Status Checks**: Always include meaningful status validation
4. **Error Handling**: Shell scripts should fail fast and clearly

### Shell Script Guidelines
1. **Set strict mode**: `set -euo pipefail`
2. **Check prerequisites**: Verify required tools exist
3. **Meaningful output**: Echo progress and status
4. **Error messages**: Clear failure descriptions

### CI/CD Guidelines
1. **Fast Feedback**: Quick validation workflows first
2. **Comprehensive Testing**: Full integration tests
3. **Failure Artifacts**: Collect logs and state on failure
4. **Resource Management**: Clean up after tests

## Migration Notes

### From Custom Status to Task Native

**Previous Approach** (removed):
- Custom JSON state files
- Complex shell script status tracking
- Manual state management

**Current Approach**:
- Task's `generates` and `status` fields
- `.task/*.done` marker files
- Native `task --status` checking

**Benefits**:
- Simpler codebase (100+ lines removed)
- Better integration with Task ecosystem
- More reliable status detection
- Easier debugging and maintenance

### Task Ordering

**Previous**: Alphabetical listing (`task --list`)
**Current**: Logical order (`task --list --sort=none`)

This ensures tasks appear in execution order, making the interface more intuitive for users.

## Future Enhancements

### Potential Improvements
1. **Multi-platform Support**: Add macOS/Windows specific tasks
2. **Configuration Management**: External config file support
3. **Advanced Monitoring**: Prometheus/Grafana integration
4. **Security Scanning**: Add security validation workflows
5. **Performance Testing**: Load testing workflows

### Monitoring Additions
1. **Health Checks**: Automated endpoint testing
2. **Metrics Collection**: Setup telemetry
3. **Alerting**: Integration with monitoring systems

## Support

For maintenance questions:
1. Check this document first
2. Review Task documentation: https://taskfile.dev/
3. Check GitHub Actions logs for CI/CD issues
4. Review project issues and discussions

---

**Last Updated**: January 2025
**Maintainer**: Project Team
**Task Version**: 3.x
**Kind Version**: v0.29.0
