import { Result } from './result';
import { Failure } from './failure';

export interface UseCase<IRequest, IResponse> {
  execute(request: IRequest): Promise<Result<IResponse, Failure>>;
}
