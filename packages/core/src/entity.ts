import { randomUUID } from 'crypto';

export abstract class Entity<T> {
  public readonly id: string;
  protected props: T;

  constructor(props: T, id?: string) {
    this.id = id || randomUUID();
    this.props = props;
  }

  public equals(object?: Entity<T>): boolean {
    if (object === null || object === undefined) {
      return false;
    }
    if (this === object) {
      return true;
    }
    return this.id === object.id;
  }
}
