export class Result<T, E = Error> {
  private constructor(
    public readonly isSuccess: boolean,
    public readonly error?: E,
    private readonly value?: T,
  ) {}

  public static ok<U, E = Error>(value: U): Result<U, E> {
    return new Result<U, E>(true, undefined, value);
  }

  public static fail<U, E = Error>(error: E): Result<U, E> {
    return new Result<U, E>(false, error, undefined);
  }

  public getValue(): T {
    if (!this.isSuccess || this.value === undefined) {
      throw new Error('Cannot retrieve value from a failed or empty Result.');
    }
    return this.value;
  }

  public getError(): E {
    if (this.isSuccess || this.error === undefined) {
      throw new Error('Cannot retrieve error from a successful Result.');
    }
    return this.error;
  }
}
