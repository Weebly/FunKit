[![master][master-badge]][builds]
[![Documentation][docs-badge]][docs]
# Pipelines. Promises. Railways. Your way.

**FunKit** is a functional toolkit for [Swift][swift]. It integrates [railway-oriented programming][railways] with [promises][promises], providing a novel way to build Swift applications.

```swift
enum App {

    static func main(context: AppContext) -> Bool {

        func addOKAction(alert: UIAlertController) {
            (title: "OK", style: .default, handler: nil)
                |> UIAlertAction.init
                |> alert.addAction
        }

        let showAlert = UIAlertController.init(title:message:preferredStyle:)
            >>> tee(addOKAction)
            >>> curry(reverse(context.viewController.present))(nil)(true)

        func success<A>(_: A) {
            (title: "Initialized", message: nil, preferredStyle: .alert)
                |> showAlert
        }

        func failure(error: Error) {
            (title: "Failed", message: error.localizedDescription, preferredStyle: .alert)
                |> showAlert
        }

        func done() { print("Initialization complete") }
        
        func returnTrue<A>(_: A) -> Bool { return true }

        return ()
            |> context.initialize
            |> Promise.main
            ?> success
            !> failure
            *> done
            |> returnTrue
    }

}
```

### Pipelines

Pipelines let you build functions like shell commands, where the output of one function is the input of another. This reduces the need for temporary variables while maintaining readability, using the `|>` operator. The compose operator (`>>>`) can be used to build pipeline functions, when there isn't a value to feed into it right away.

### Railways

[Railways][railways] improve upon pipelines by allowing methods to return a value denoting some sort of error condition. Traditional functions can be adapted using `turnout`, removing the need to manually check for errors at every step.

The `unwrap` function converts `nil` values to failures, while `tryCatch` does the same for thrown `Error`s.

### Promises

[Promises][promises] are considered asynchronous railways. They can be created directly from railway `Result`s, or fulfilled or rejected asynchronously. Syntactic sugar operators such as `?>`, `!>`, and `*>` make it easy to integrate promises with pipelines and railways.

### Lazy Evaluation

**FunKit** makes extensive use of `@autoclosure` in an effort to provide lazy evaluation. However, the performance impacts have not been looked into.

[builds]: https://travis-ci.org/Weebly/FunKit
[master-badge]: https://img.shields.io/travis/Weebly/FunKit/master.svg
[docs]: https://weebly.github.io/FunKit/
[docs-badge]: https://weebly.github.io/FunKit/badge.svg
[promises]: https://promisesaplus.com/
[railways]: https://fsharpforfunandprofit.com/posts/recipe-part2/
[swift]: https://swift.org/