# Contributing to OneTimeSecret

Thank you for your interest in contributing to OneTimeSecret! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/your-username/ots4.git
   cd ots4
   ```
3. Add the upstream repository:
   ```bash
   git remote add upstream https://github.com/original-owner/ots4.git
   ```
4. Install dependencies:
   ```bash
   mix deps.get
   cd assets && npm install && cd ..
   ```
5. Set up the database:
   ```bash
   mix onetimesecret.setup
   ```

## Development Workflow

1. Create a new branch for your feature or bugfix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes following the coding standards below

3. Run tests to ensure everything works:
   ```bash
   mix test
   ```

4. Format your code:
   ```bash
   mix format
   ```

5. Commit your changes with a descriptive commit message:
   ```bash
   git commit -m "Add feature: your feature description"
   ```

6. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

7. Open a Pull Request on GitHub

## Coding Standards

### Elixir Code

- Follow the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
- Use `mix format` before committing
- Write comprehensive documentation using `@moduledoc` and `@doc` attributes
- Add typespecs to public functions when appropriate
- Keep functions small and focused (generally under 20 lines)
- Use pattern matching and guard clauses effectively

### Phoenix/LiveView

- Follow Phoenix conventions for contexts, controllers, and LiveViews
- Keep business logic in contexts, not controllers or LiveViews
- Use changesets for data validation
- Implement proper error handling

### Testing

- Write tests for all new features
- Maintain test coverage above 80%
- Use descriptive test names that explain what is being tested
- Follow the Arrange-Act-Assert pattern
- Use factories or fixtures for test data

### Documentation

- Update the README.md if you add new features
- Add inline comments for complex logic
- Keep documentation up-to-date with code changes

## Pull Request Process

1. Ensure your PR description clearly describes the problem and solution
2. Include the relevant issue number if applicable
3. Update documentation as needed
4. Add or update tests as needed
5. Ensure all tests pass
6. Request review from maintainers

### PR Title Format

Use conventional commit format for PR titles:

- `feat: add new feature`
- `fix: resolve bug in secret retrieval`
- `docs: update API documentation`
- `test: add tests for encryption`
- `refactor: improve cache performance`
- `chore: update dependencies`

## Security Issues

**DO NOT** open public issues for security vulnerabilities.

Instead, please email security@example.com with:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

## Feature Requests

Feature requests are welcome! Please:

1. Check if the feature has already been requested
2. Open an issue with the "feature request" label
3. Clearly describe the feature and its use case
4. Explain why it would be valuable to the project

## Questions?

If you have questions about contributing:

- Open a discussion on GitHub Discussions
- Check existing documentation
- Review closed issues and PRs

## License

By contributing to OneTimeSecret, you agree that your contributions will be licensed under the Apache License 2.0.

## Recognition

Contributors will be recognized in the project's README and release notes.

Thank you for contributing to OneTimeSecret! 🎉
